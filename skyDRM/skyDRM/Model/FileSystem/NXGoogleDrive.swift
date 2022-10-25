//
//  NXGoogleDrive.swift
//  skyDRM
//
//  Created by nextlabs on 30/12/2016.
//  Copyright © 2016 nextlabs. All rights reserved.
//

import Foundation

class NXGoogleDrive : NSObject, NXServiceOperation
{

    private static let kKeyGoogleDriveRoot = "root"
    private static let kKeyGetFiles = "getfiles"
    private static let kKeyDownloadFile = "downloadfile"
    private static let kKeyDownloadDstPath = "downloadDstPath"
    private static let kKeyDownloadFilePath = "downloadFilePath"
    private static let kKeyDownloadRange = "downloadRange"
    private static let kKeyDownloadIsRange = "downloadIsRange"
    private static let kKeyUploadFileDstPath = "uploadfiledstpath"
    private static let kKeyUpdateFileSrcPath = "updatefilesrcpath"
    private static let kKeyUpdateFileDstFile = "updatefiledstfile"
    private static let kKeyGetMetaData = "getmetadata"
    private static let kKeyAddFolderParentFolder = "addFolderParentFolder"
    private static let kKeyAddFolderNewFolderName = "addFolderNewFolderName"
    private static let kKeyDeleteItemServicePath = "deleteItemServicePath"
    fileprivate static let kGoogleDriveFolderMimetype = "application/vnd.google-apps.folder"
    
    enum ExportableMimeType {
        case sheet
        case drawing
        case presentation
        case document
        func description() -> String {
            switch self {
            case .document:
                return "application/vnd.google-apps.document"
            case .sheet:
                return "application/vnd.google-apps.spreadsheet"
            case .presentation:
                return "application/vnd.google-apps.presentation"
            case .drawing:
                return "application/vnd.google-apps.drawing"
            }
        }
        func exportMimeType() -> String {
            switch self {
            case .document:
                return "application/vnd.openxmlformats-officedocument.wordprocessingml.document"
            case .sheet:
                return "application/vnd.openxmlformats-officedocument.spreadsheetml.sheet"
            case .presentation:
                return "application/vnd.openxmlformats-officedocument.presentationml.presentation"
            case .drawing:
                return "image/png"
            }
        }
        func exportExtension() -> String {
            switch self {
            case .document:
                return ".docx"
            case .sheet:
                return ".xlsx"
            case .presentation:
                return ".pptx"
            case .drawing:
                return ".png"
            }
        }
    }
    
    
    private var driveService = GTLRDriveService()
    private var userInfoTicket: GTLRServiceTicket?
    private var isLinked = false
    private var userId = String()
    private var alias = String()
    
    private var downloadOrUploadId : Int? = nil
    private var downloadFetch : GTMSessionFetcher? = nil
    private var uploadTicket : GTLRServiceTicket? = nil
    private var exportTicket: GTLRServiceTicket?
    private var cancelledDownload : Bool = false
    
    private var listFilesTickets = NSMutableDictionary()
    private var updateFileTickets = NSMutableDictionary()
    private var metaDataTickets = NSMutableDictionary()
    private var recursiveFileList = NSMutableArray()
    private var enumFolderStack = NSMutableArray()
    private var curFolder = NXFileBase()
    private var newList = NSMutableArray()
    weak var delegate : NXServiceOperationDelegate?
    
    private let serial = DispatchQueue(label: "com.skyDRM.NXGoogleDrive", attributes: .concurrent)
    
    init(userId : String!, alias: String!, accessToken: String!) {
        super.init()
        self.userId = userId
        self.alias = alias
//        guard let property = NXCommonUtils.parseGoogleDriveToken(token: accessToken),
//            let keychain = property["keychainName"] as? String else {
//            Swift.print("Google Drive invalid token")
//            return
//        }
        guard let auth = GTMAppAuthFetcherAuthorization(fromKeychainForName: accessToken) else {
            return
        }
        self.driveService.authorizer = auth
        if  auth.canAuthorize() {
            Swift.print("Google Drive Authentication succeeded")
            isLinked = true
        }
        else{
            Swift.print("Google Drive Authentication failed")
        }
    }
    
    //MARK: NXServiceOperation
    func getFiles(folder: NXFileBase) -> Bool {
        guard isLinked == true,
            folder is NXFolder else {
            return false
        }
        if folder.isRoot {
            folder.fullPath = "/"
            folder.fullServicePath = NXGoogleDrive.kKeyGoogleDriveRoot
        }
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "trashed = false and '\(folder.fullServicePath)' IN parents"
        query.fields = "nextPageToken, files(mimeType,id,name,trashed,modifiedTime,size,webContentLink)"
        query.pageSize = 1000
        query.executionParameters.ticketProperties = [NXGoogleDrive.kKeyGetFiles: folder]
        self.driveService.shouldFetchNextPages = false
        
        let fileListTicket = self.driveService.executeQuery(query, delegate: self, didFinish: #selector(self.getFilesFinished(ticket:fileList:error:)))
        self.listFilesTickets.setObject(fileListTicket, forKey: folder.fullServicePath as NSCopying)
        return true
    }
    
    func getAllFilesInFolder(folder: NXFileBase) -> Bool {
        guard isLinked == true,
            folder is NXFolder else {
            return false
        }
       
        self.curFolder = folder
        self.enumFolderStack.add(folder)
        
        let query = GTLRDriveQuery_FilesList.query()
        query.q = "trashed = false and '\(folder.fullServicePath)' IN parents"
        self.driveService.shouldFetchNextPages = true
        
        let fileListTicket = self.driveService.executeQuery(query, delegate: self, didFinish: #selector(self.recurGetFilesFinished(ticket:fileList:error:)))
        query.executionParameters.ticketProperties = [NXGoogleDrive.kKeyGetFiles: folder]
        self.listFilesTickets.setObject(fileListTicket, forKey: NXGoogleDrive.kKeyGetFiles as NSCopying)
        return true
    }
    
    func cancelGetFiles(folder: NXFileBase) -> Bool {
        guard isLinked == true else {
            return false
        }
        
        guard let fileTicket = self.listFilesTickets.object(forKey: folder.fullServicePath) as? GTLRServiceTicket else {
            return false
        }
        fileTicket.cancel()
        self.listFilesTickets.removeObject(forKey: folder.fullServicePath)
        
        let error = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
        
        self.delegate?.getFilesFinished?(folder: folder, files: nil, error: error)
        return true
    }
    
    func downloadFile(file: NXFileBase, filePath: String, id: Int) -> Bool {
        guard isLinked == true,
            file is NXFile else {
            return false
        }
        guard let mimetype = file.extraInfor[NXFileBase.Constant.kGoogleMimeType] as? String else {
            return false
        }
        if let exportMt = supportExport(description: mimetype){
            let query = GTLRDriveQuery_FilesExport.queryForMedia(withFileId: file.fullServicePath, mimeType: exportMt.exportMimeType())
            let exportPath = filePath.appending(exportMt.exportExtension())
            setExportFileExtension(file: file, ext: exportMt.exportExtension())
            query.executionParameters.ticketProperties = [NXGoogleDrive.kKeyDownloadFile: file, NXGoogleDrive.kKeyDownloadDstPath: exportPath]
            exportTicket = self.driveService.executeQuery(query, delegate: self, didFinish: #selector(self.exportFinished(ticket:response:error:)))
        }
        else if let webContentLink = file.extraInfor[NXFileBase.Constant.kGoogleWebcontentLink] as? String {
            downloadFetch = self.driveService.fetcherService.fetcher(withURLString: webContentLink)
            downloadFetch?.properties = [NXGoogleDrive.kKeyDownloadFile: file, NXGoogleDrive.kKeyDownloadDstPath: filePath]
            
            downloadFetch?.receivedProgressBlock = {write, total in
                guard let property = self.downloadFetch?.properties as NSDictionary?,
                    let response = self.downloadFetch?.response,
                    response.expectedContentLength != 0,
                    response.expectedContentLength != -1,
                    let _  = property.object(forKey: NXGoogleDrive.kKeyDownloadFile) as? NXFile else {
                        return
                }
                
                let progress = Float((self.downloadFetch?.downloadedLength)!) / Float(response.expectedContentLength)
                self.delegate?.updateProgress?(id: self.downloadOrUploadId!, progress: progress)
            }
            
            downloadFetch?.beginFetch(withDelegate: self, didFinish: #selector(self.downloadFinished(fetcher:data:error:)))
        }
        else {
            let delayQueue = DispatchQueue(label: "com.nxrmc.skyDRM.Google.timer")
            let deadlineTime = DispatchTime.now() + .seconds(1)
            delayQueue.asyncAfter(deadline: deadlineTime, execute: {_ in
                let retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CONVERTFILEFAILED_NOSUPPORTED, error: nil)!
                self.delegate?.downloadOrUploadFinished?(id: id, error: retError)
            })
        }
        downloadOrUploadId = id
        return true
    }
    
    func rangeDownloadFile(file: NXFileBase, length: Int, filePath: String, id: Int) -> Bool {
        guard isLinked == true,
            file is NXFile else {
                return false
        }
        guard let webContentLink = file.extraInfor[NXFileBase.Constant.kGoogleWebcontentLink] as? String else {
            return false
        }
        downloadFetch = self.driveService.fetcherService.fetcher(withURLString: webContentLink, range: NSMakeRange(0, length))
        downloadFetch?.properties = [NXGoogleDrive.kKeyDownloadFile: file, NXGoogleDrive.kKeyDownloadDstPath: filePath]
        
        downloadFetch?.receivedProgressBlock = {write, total in
            guard let property = self.downloadFetch?.properties as NSDictionary?,
                let response = self.downloadFetch?.response,
                response.expectedContentLength != 0,
                response.expectedContentLength != -1,
                let _ = property.object(forKey: NXGoogleDrive.kKeyDownloadFile) as? NXFile else {
                    return
            }
            
            let progress = Float((self.downloadFetch?.downloadedLength)!) / Float(response.expectedContentLength)
            self.delegate?.updateProgress?(id: self.downloadOrUploadId!, progress: progress)
        }
        
        downloadFetch?.beginFetch(withDelegate: self, didFinish: #selector(self.rangeDownloadFinished(fetcher:data:error:)))
        
        downloadOrUploadId = id
        
        return true
    }
    
    func deleteFileFolder(file: NXFileBase) -> Bool {
        guard isLinked == true else {
            return false
        }
        let query = GTLRDriveQuery_FilesDelete.query(withFileId: file.fullServicePath)
        query.executionParameters.ticketProperties = [NXGoogleDrive.kKeyDeleteItemServicePath: file.fullServicePath]
        let _ = self.driveService.executeQuery(query, delegate: self, didFinish: #selector(self.deleteFileFinished(ticket:obj:error:)))
        return true
    }
    
    func addFolder(folderName: String, parentFolder: NXFileBase) -> Bool {
        guard isLinked == true,
            parentFolder is NXFolder else {
            return false
        }
        if parentFolder.isRoot {
            parentFolder.fullPath = "/"
            parentFolder.fullServicePath = NXGoogleDrive.kKeyGoogleDriveRoot
        }
        let folder = GTLRDrive_File()
        folder.name = folderName
        folder.mimeType = NXGoogleDrive.kGoogleDriveFolderMimetype
        folder.parents = [parentFolder.fullServicePath]
        let query = GTLRDriveQuery_FilesCreate.query(withObject: folder, uploadParameters: nil)
        query.executionParameters.ticketProperties = [NXGoogleDrive.kKeyAddFolderParentFolder: parentFolder, NXGoogleDrive.kKeyAddFolderNewFolderName: folderName]
        let _ = self.driveService.executeQuery(query, delegate: self, didFinish: #selector(self.createFolderFinished(ticket:drivefolder:error:)))
        return true
    }
    
    func uploadFile(filename: String, folder: NXFileBase, srcPath: String, fileSource: NXFileBase? = nil, id: Int) -> Bool {
        guard isLinked == true,
            folder is NXFolder else {
            return false
        }
        
        if folder.isRoot {
            folder.fullPath = "/"
            folder.fullServicePath = NXGoogleDrive.kKeyGoogleDriveRoot
        }
        
        guard let mimeType = NXCommonUtils.getMimeType(filepath: srcPath),
            let data = try? Data(contentsOf: URL(fileURLWithPath: srcPath)) else {
                return false
        }
        
        let uploadParam = GTLRUploadParameters(data: data, mimeType: mimeType)
        let metaData = GTLRDrive_File()
        metaData.name = filename
        metaData.parents = [folder.fullServicePath]
        
        let query = GTLRDriveQuery_FilesCreate.query(withObject: metaData, uploadParameters: uploadParam)
//        query.executionParameters.uploadProgressBlock = #selector(self.uploadProgress(ticket:uploaded:expectedUpload:))
        let uploadTicket = self.driveService.executeQuery(query, delegate: self, didFinish: #selector(self.uploadFinished(ticket:drivefile:error:)))
        
        self.uploadTicket = uploadTicket
        downloadOrUploadId = id
        
        return true
    }
    
    func cancelDownloadOrUpload(id: Int) {
        guard isLinked == true, self.downloadOrUploadId == id else {
            return
        }
        
        cancelledDownload = true
        downloadFetch?.stopFetching()
        uploadTicket?.cancel()
        exportTicket?.cancel()
        
        serial.async {
            let error = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
            self.delegate?.downloadOrUploadFinished?(id: id, error: error)
        }
        
        return
    }
    
    func updateFile(srcPath: String, dstFile: NXFileBase) -> Bool {
        guard isLinked == true,
            dstFile is NXFile else {
                return false
        }
        
        guard let mimeType = NXCommonUtils.getMimeType(filepath: srcPath),
            let data = try? Data(contentsOf: URL(fileURLWithPath: srcPath)) else {
                return false
        }
        let updateParam = GTLRUploadParameters(data: data, mimeType: mimeType)
        
        let metaData = GTLRDrive_File()
        let query = GTLRDriveQuery_FilesUpdate.query(withObject: metaData, fileId: dstFile.fullServicePath, uploadParameters: updateParam)
        //        query.executionParameters.uploadProgressBlock = #selector(self.updateProgress(ticket:uploaded:expectedUpload:))
        query.executionParameters.ticketProperties = [NXGoogleDrive.kKeyUpdateFileSrcPath: srcPath, NXGoogleDrive.kKeyUpdateFileDstFile: dstFile]
        let updateTicket = self.driveService.executeQuery(query, delegate: self, didFinish: #selector(self.updateFinished(ticket:drivefile:error:)))
        
        let key = getUpdateTicketKey(srcPath: srcPath, dstFile: dstFile)
        self.updateFileTickets.setObject(updateTicket, forKey: key as NSCopying)
        return true

    }
    
    func cancelUpdateFile(srcPath: String, dstFile: NXFileBase) -> Bool {
        guard isLinked == true else {
            return false
        }
        let key = getUpdateTicketKey(srcPath: srcPath, dstFile: dstFile)
        guard let ticket = self.updateFileTickets.object(forKey: key) as? GTLRServiceTicket else {
            return false
        }
        
        ticket.cancel()
        self.updateFileTickets.removeObject(forKey: key)
        let error = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
        self.delegate?.updateFileFinished?(srcPath: srcPath, fileServicePath: dstFile.fullServicePath, error: error)
        return true
    }
    
    func getMetaData(file: NXFileBase) -> Bool {
        guard isLinked == true,
            file.isRoot == false else {
            return false
        }
        let query = GTLRDriveQuery_FilesGet.query(withFileId: file.fullServicePath)
        query.fields = "mimeType,id,name,trashed,modifiedTime,size,webContentLink"
        query.executionParameters.ticketProperties = [NXGoogleDrive.kKeyGetMetaData: file]
        
        let ticket = self.driveService.executeQuery(query, delegate: self, didFinish: #selector(self.getMetaDataFinished(ticket:file:error:)))
        self.metaDataTickets.setObject(ticket, forKey: file.fullServicePath as NSCopying)
        return true
    }
    
    func cancelGetMetaData(file: NXFileBase) -> Bool {
        guard isLinked == true else {
            return false
        }
        let ticket = self.metaDataTickets.object(forKey: file.fullServicePath) as?GTLRServiceTicket
        guard ticket != nil else {
            return false
        }
        ticket?.cancel()
        self.metaDataTickets.removeObject(forKey: file.fullServicePath)
        let error = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
        self.delegate?.getMetaDataFinished?(servicePath: file.fullServicePath, error: error)
        return true
    }
    
    func setDelegate(delegate: NXServiceOperationDelegate) {
        self.delegate = delegate
    }
    
    func isProgressSupported() -> Bool {
        return true
    }
    
    func setAlias(alias : String){
        self.alias = alias
    }
    
    func getServiceAlias() -> String{
        return self.alias
    }
    
    func getMetaDataFinished(ticket: GTLRServiceTicket?, file: GTLRDrive_File?, error: NSError?)  {
        guard let ticket = ticket,
            let property = ticket.ticketProperties as NSDictionary?,
            let metafile = property.object(forKey: NXGoogleDrive.kKeyGetMetaData) as? NXFileBase else {
                assertionFailure()
                return
        }
        self.metaDataTickets.removeObject(forKey: metafile.fullServicePath)
        if let error = error {
            let retError = convertErrorIntoNXError(error: error)
            self.delegate?.getMetaDataFinished?(servicePath: metafile.fullServicePath, error: retError)
        }
        else if let file = file {
            var retError : NSError?
            if file.explicitlyTrashed?.boolValue == true {
                retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE, error: nil)
                self.delegate?.getMetaDataFinished?(servicePath: metafile.fullServicePath, error: retError)
            }
            else{
                guard let parent = metafile.parent else {
                    retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE, error: nil)
                    self.delegate?.getMetaDataFinished?(servicePath: metafile.fullServicePath, error: retError)
                    return
                }
                self.fetchFile(nxfile: metafile, driveFile: file, parent: parent)
                self.delegate?.getMetaDataFinished?(servicePath: metafile.fullServicePath, error: nil)
            }
        }
    }
    
    func getUserInfo() -> Bool {
        guard isLinked == true else {
            return false
        }
        let query = GTLRDriveQuery_AboutGet.query()
        let userInfoTicket = self.driveService.executeQuery(query, delegate: self, didFinish: #selector(self.getUserInfoFinished(ticket:info:error:)))
        self.userInfoTicket = userInfoTicket
        return true
    }
    
    func cancelGetUserInfo() -> Bool {
        guard isLinked == true else {
            return false
        }
        self.userInfoTicket?.cancel()
        let error = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
        self.delegate?.getUserInfoFinished?(username: nil, email: nil, totalQuota: nil, usedQuota: nil, error: error)
        return true
    }
    
    //MARK: GoogleDrive
    func getFilesFinished(ticket : GTLRServiceTicket?, fileList : GTLRDrive_FileList?, error : NSError?){
        guard let property = ticket?.ticketProperties as NSDictionary?,
            let folder = property.object(forKey: NXGoogleDrive.kKeyGetFiles) as? NXFileBase else {
                assertionFailure()
                return
        }

        if let error = error {
            let retError = self.convertErrorIntoNXError(error: error)
            self.delegate?.getFilesFinished?(folder: folder, files: nil, error: retError)
        }
        else if let files = fileList?.files {
            for drivefile in files {
                var nxfile: NXFileBase!
                if  drivefile.mimeType == NXGoogleDrive.kGoogleDriveFolderMimetype{
                    nxfile = NXFolder()
                }
                else{
                    nxfile = NXFile()
                }
                self.fetchFile(nxfile: nxfile, driveFile: drivefile, parent: folder)
                nxfile.isOffline = false
                nxfile.isFavorite = false
                nxfile.parent = folder
                newList.add(nxfile)
            }
            
            if fileList?.nextPageToken == nil {
                NXCommonUtils.updateFolderChildren(folder: folder, newFileList: newList)
                self.delegate?.getFilesFinished?(folder: folder, files: folder.getChildren(), error: nil)
            } else {
                let query = GTLRDriveQuery_FilesList.query()
                
                query.q = "trashed = false and '\(folder.fullServicePath)' IN parents"
                query.fields = "nextPageToken, files(mimeType,id,name,trashed,modifiedTime,size,webContentLink)"
                query.pageSize = 1000
                query.pageToken = fileList?.nextPageToken
                query.executionParameters.ticketProperties = [NXGoogleDrive.kKeyGetFiles: folder]
                
                let fileListTicket = self.driveService.executeQuery(query, delegate: self, didFinish: #selector(self.getFilesFinished(ticket:fileList:error:)))
                self.listFilesTickets.setObject(fileListTicket, forKey: folder.fullServicePath as NSCopying)
            }
        }
        else {
            folder.removeAllChildren()
            self.delegate?.getFilesFinished?(folder: folder, files: nil, error: nil)
        }
    }
    
    func recurGetFilesFinished(ticket: GTLRServiceTicket?, fileList: GTLRDrive_FileList?, error: NSError?){
        self.enumFolderStack.removeLastObject()
        guard let property = ticket?.ticketProperties as NSDictionary?,
            let folder = property.object(forKey: NXGoogleDrive.kKeyGetFiles) as? NXFileBase else {
                assertionFailure()
                return
        }
        self.listFilesTickets.removeObject(forKey: folder.fullServicePath)
        if let files = fileList?.files {
            for drivefile in files {
                var nxfile: NXFileBase!
                if drivefile.mimeType == NXGoogleDrive.kGoogleDriveFolderMimetype {
                    nxfile = NXFolder()
                }
                else{
                    nxfile = NXFile()
                }
                self.fetchFile(nxfile: nxfile, driveFile: drivefile, parent: folder)
                
                if nxfile is NXFile {
                    self.recursiveFileList.add(nxfile)
                }
                else if nxfile is NXFolder{
                    self.enumFolderStack.add(nxfile)
                }
            }
        }
        
        while self.enumFolderStack.count != 0 {
            if (self.enumFolderStack.lastObject as? NXFolder) != nil {
                break
            }
            else {
                self.enumFolderStack.removeLastObject()
            }
        }
        if self.enumFolderStack.count == 0 {
            self.delegate?.getAllFiles?(servicePath: self.curFolder.fullServicePath, files: self.recursiveFileList, error: nil)
            self.recursiveFileList.removeAllObjects()
            self.enumFolderStack.removeAllObjects()
        }
        else{
            let folder = self.enumFolderStack.lastObject as! NXFolder
            let query = GTLRDriveQuery_FilesList.query()
            query.q = "trashed = false and '\(folder.fullServicePath)' IN parents"
            query.executionParameters.ticketProperties = [NXGoogleDrive.kKeyGetFiles: folder]
            self.driveService.shouldFetchNextPages = true
            let fileTicket = self.driveService.executeQuery(query, delegate: self, didFinish: #selector(NXGoogleDrive.recurGetFilesFinished(ticket:fileList:error:)))
            self.listFilesTickets.setObject(fileTicket, forKey: folder.fullServicePath as NSCopying)
        }
        
    }
    
    func downloadFinished(fetcher: GTMSessionFetcher?, data: NSData?, error: NSError?) {
        guard let fetcher = fetcher else {
            return
        }
        
        guard let property = fetcher.properties as NSDictionary?,
            let _ = property.object(forKey: NXGoogleDrive.kKeyDownloadFile) as? NXFile,
            let cachePath  = property.object(forKey: NXGoogleDrive.kKeyDownloadDstPath) as? String else {
                assertionFailure()
                return
        }
        
        var retError: NSError?
        if let error = error {
            retError = self.convertErrorIntoNXError(error: error)
            self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
        }
        else if let data = data {
            if data.write(toFile: cachePath, atomically: true) == false{
                retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_RENDER_FILE_FAILED, error: nil)
            }
            self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
        }
        else {
            self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: nil)
        }
    }
    
    func exportFinished(ticket: GTLRServiceTicket?, response: GTLRDataObject?, error: NSError?) {
        guard let ticket = ticket else {
            return
        }
        
        guard let property = ticket.ticketProperties as NSDictionary?,
            let _ = property.object(forKey: NXGoogleDrive.kKeyDownloadFile) as? NXFile,
            let cachePath  = property.object(forKey: NXGoogleDrive.kKeyDownloadDstPath) as? String else {
                assertionFailure()
                return
        }
        
        var retError: NSError?
        if let error = error {
            retError = self.convertErrorIntoNXError(error: error)
            self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
        }
        else if let data = response?.data {
            
            let pathUrl = URL(fileURLWithPath: cachePath, isDirectory: false)
            do {
                try data.write(to: pathUrl)
                self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: nil)
            }
            catch {
                retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_RENDER_FILE_FAILED, error: nil)
                self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
            }
        }
    }
    func rangeDownloadFinished(fetcher: GTMSessionFetcher?, data: NSData?, error: NSError?) {
        guard let fetcher = fetcher else {
            return
        }
        
        guard let property = fetcher.properties as NSDictionary?,
            let _ = property.object(forKey: NXGoogleDrive.kKeyDownloadFile) as? NXFile,
            let cachePath  = property.object(forKey: NXGoogleDrive.kKeyDownloadDstPath) as? String else {
                assertionFailure()
                return
        }
        
        var retError: NSError?
        if let error = error {
            retError = self.convertErrorIntoNXError(error: error)
            self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
        }
        else if let data = data {
            if data.write(toFile: cachePath, atomically: true) == false{
                retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_FILE_ACCESS_DENIED, error: nil)
            }
            self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
        }
        else {
            self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: nil)
        }
    }

    func deleteFileFinished(ticket: GTLRServiceTicket?, obj: Any, error: NSError?) {
        guard let ticket = ticket,
            let property = ticket.ticketProperties as NSDictionary?,
            let servicePath = property.object(forKey: NXGoogleDrive.kKeyDeleteItemServicePath) as? String else {
                assertionFailure()
                return
        }
        var retError: NSError?
        if let error = error {
            retError = convertErrorIntoNXError(error: error)
        }
        
        self.delegate?.deleteFileFolderFinished?(servicePath: servicePath, error: retError)
    }
    
    func createFolderFinished(ticket : GTLRServiceTicket?, drivefolder : GTLRDrive_File?, error : NSError?){
        guard let property = ticket?.ticketProperties as NSDictionary?,
            let folderName = property.object(forKey: NXGoogleDrive.kKeyAddFolderNewFolderName) as? String,
            let parentFolder = property.object(forKey: NXGoogleDrive.kKeyAddFolderParentFolder) as? NXFileBase else {
                assertionFailure()
                return
        }
        var retError: NSError?
        if let error = error {
            retError = convertErrorIntoNXError(error: error)
        }
        else if let drivefolder = drivefolder {
            let folder = NXFolder()
            self.fetchFile(nxfile: folder, driveFile: drivefolder, parent: parentFolder)
        }
        self.delegate?.addFolderFinished?(folderName: folderName, parentServicePath: parentFolder.fullServicePath, error: retError)
    }
    
    func uploadProgress(ticket: GTLRServiceTicket?, uploaded: UInt64, expectedUpload: UInt64){
        let progress = Float(uploaded) / Float(expectedUpload)
        
        self.delegate?.updateProgress?(id: downloadOrUploadId!, progress: progress)
    }
    
    func uploadFinished(ticket: GTLRServiceTicket?, drivefile: GTLRDrive_File?, error: NSError?){
        var retError: NSError?
        if let error = error {
            retError = convertErrorIntoNXError(error: error)
        }
        self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
    }
    
    func updateProgress(ticket: GTLRServiceTicket?, uploaded: UInt64, expectedUpload: UInt64){
        let progress = Float(uploaded) / Float(expectedUpload)
        let property = ticket?.ticketProperties as NSDictionary?
        let file = property?.object(forKey: NXGoogleDrive.kKeyUpdateFileDstFile) as? NXFileBase
        let srcPath = property?.object(forKey: NXGoogleDrive.kKeyUpdateFileSrcPath) as? String
        
        self.delegate?.updateFileProgress?(progress: progress, srcPath: srcPath, fileServicePath: file?.fullServicePath)
    }
    
    func updateFinished(ticket: GTLRServiceTicket?, drivefile: GTLRDrive_File?, error: NSError?){
        guard let property = ticket?.ticketProperties as NSDictionary?,
            let srcPath = property.object(forKey: NXGoogleDrive.kKeyUpdateFileSrcPath) as? String,
            let dstFile = property.object(forKey: NXGoogleDrive.kKeyUpdateFileDstFile) as? NXFileBase else {
                assertionFailure()
                return
        }
        let key = getUpdateTicketKey(srcPath: srcPath, dstFile: dstFile)
        self.updateFileTickets.removeObject(forKey: key)
        var retError: NSError?
        if let error = error {
            retError = convertErrorIntoNXError(error: error)
        }
        self.delegate?.updateFileFinished?(srcPath: srcPath, fileServicePath: dstFile.fullServicePath, error: retError)
    }
    
    func getUserInfoFinished(ticket: GTLRServiceTicket?, info: GTLRDrive_About?, error: NSError?)  {
        var retError: NSError?
        if let error = error {
            retError = convertErrorIntoNXError(error: error)
        }
        self.delegate?.getUserInfoFinished?(username: info?.user?.displayName, email: info?.user?.emailAddress, totalQuota: info?.storageQuota?.limit, usedQuota: info?.storageQuota?.usageInDrive, error: retError)
    }
    
    //MARK: private method
    private func fetchFile(nxfile: NXFileBase, driveFile: GTLRDrive_File, parent: NXFileBase) {
        guard let name = driveFile.name,
            let id = driveFile.identifier else {
                return
        }
        nxfile.name = name
        if let fullPath = NSURL(fileURLWithPath: parent.fullPath).appendingPathComponent(name)?.path {
            nxfile.fullPath = fullPath
            if nxfile is NXFolder {
                nxfile.fullPath.append("/")
            }
        }
        nxfile.fullServicePath = id
        nxfile.serviceAccountId = self.userId
        nxfile.serviceAlias = self.alias
        
        if let modifiedTime = driveFile.modifiedTime {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timeString = formatter.string(from: modifiedTime.date as Date)
            
            nxfile.lastModifiedDate = modifiedTime.date as NSDate
            nxfile.lastModifiedTime = timeString
        }
        if let size = driveFile.size {
            nxfile.size = size.int64Value
        }
        nxfile.serviceType = NSNumber(value: ServiceType.kServiceGoogleDrive.rawValue)
        nxfile.isRoot = false
        nxfile.boundService = parent.boundService
        if let webcontent = driveFile.webContentLink {
            nxfile.extraInfor[NXFileBase.Constant.kGoogleWebcontentLink] = webcontent
        }
        if let mimetype = driveFile.mimeType {
            nxfile.extraInfor[NXFileBase.Constant.kGoogleMimeType] = mimetype
        }
    }
    private func setExportFileExtension(file: NXFileBase, ext: String) {
        file.extraInfor[NXFileBase.Constant.kGoogleExportExtension] = ext
    }
    private func convertErrorIntoNXError(error: NSError) -> NSError? {
        var retError: NSError? = error
        if 400 == error.code {
            if error.userInfo["error"] as? String == "invalid_grant"{
                retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED, error: error)
            }
        }
        else if 401 == error.code {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED, error: error)
        }
        else if 403 == error.code{
            if error.userInfo["error"] as? String == "The user's Drive storage quota has been exceeded."{
                retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_DRIVE_STORAGE_EXCEEDED, error: error)
            } else {
                retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED, error: error)
            }
        }
        else if error.code < 0 && error.code != NSURLErrorCancelled{
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_TRANS_BYTES_FAILED, error: error)
        }
        else if error.code == 404 {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE, error: error)
        }
        return retError
    }
    
    private func getUploadTicketKey(srcPath: String, folder: NXFileBase) -> String {
        return folder.fullServicePath.appending(srcPath)
    }
    private func getUpdateTicketKey(srcPath: String, dstFile: NXFileBase) -> String {
        return dstFile.fullServicePath.appending(srcPath)
    }
    private func supportExport(description: String) -> ExportableMimeType? {
        let typies: [ExportableMimeType] = [.sheet, .drawing, .presentation, .document]
        for type in typies {
            if type.description() == description {
                return type
            }
        }
        return nil
    }
}

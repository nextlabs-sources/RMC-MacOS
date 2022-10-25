//
//  NXOneDrive.swift
//  skyDRM
//
//  Created by nextlabs on 09/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation
class NXOneDrive : NSObject, NXServiceOperation {
    
    private static let NXONEDRIVE_ROOT = "root"
    
    private enum ONEDRIVE_ERRORCODE : Int {
        case ONEDRIVE_ERRORCODE_CANCEL = -999
        case ONEDRIVE_ERRORCODE_NOTFOUND = 5
    }
    
    private var userId = String()
    private var alias = String()
    private var client: ODClient?
    private var enumFolderStack = NSMutableArray()
    private var recursiveFileList = NSMutableArray()
    private var curFolder = NXFileBase()
    private var isAuthed = false
    
    private var listFilesTask = NSMutableDictionary()
    private var updateFileTask = NSMutableDictionary()
    private var metaDataTask = NSMutableDictionary()
    private var updateSrcDestPath = NSMutableDictionary()
    private var updateFile = NSMutableDictionary()
    
    private var userInfoTask: ODURLSessionTask?
    
    private var downloadContext = 0
    private var rangeDownloadContext = 0
    private var uploadContext = 0
    private var updateContext = 0
    
    private var downloadOrUploadId : Int? = nil
    private var downloadTask : ODURLSessionDownloadTask? = nil
    private var uploadTask : ODURLSessionUploadTask? = nil
    
    weak var delegate: NXServiceOperationDelegate?
    
    init(userId: String, alias: String){
        super.init()
        
        ODClient.setMicrosoftAccountAppId(ONEDRIVECLIENTID, scopes: ONEDRIVESCOPE)
        let client = ODClient.loadCurrent()
        if client != nil {
            self.client = client
            self.userId = userId
            self.alias = alias
            self.isAuthed = true
        }
        
    }
    
    //MARK: NXServiceOperation
    func getFiles(folder: NXFileBase) -> Bool {
        guard folder is NXFolder,
            isAuthed == true else{
            return false
        }
        if folder.isRoot{
            folder.fullPath = "/"
            folder.fullServicePath = NXOneDrive.NXONEDRIVE_ROOT
        }
        
        guard let task = self.client?.drive().items(folder.fullServicePath).children().request().getWithCompletion({response, nextRequest, error in
            self.getFilesFinished(files: response?.value as NSArray?, error: error as NSError?)}) else {
            return false
        }
        self.enumFolderStack.add(folder)
        self.listFilesTask.setObject(task, forKey: folder.fullServicePath as NSCopying)
        return true
    }
    
    func getAllFilesInFolder(folder: NXFileBase) -> Bool {
        guard isAuthed == true,
            folder is NXFolder else {
            return false
        }
        self.curFolder = folder
        self.enumFolderStack.add(folder)
        
        guard let task = self.client?.drive().items(folder.fullServicePath).children().request().getWithCompletion({response, nextRequest, error in
            if error == nil{
                self.recurGetFilesFinished(files: response?.value as NSArray?, error: nil)
            }
            else{
                self.recurGetFilesFinished(files: nil, error: error as NSError?)
            }
        }) else {
            return false
        }
        self.listFilesTask.setObject(task, forKey: folder.fullServicePath as NSCopying)
        return true
    }
    
    func cancelGetFiles(folder: NXFileBase) -> Bool {
        guard isAuthed == true else {
            return false
        }
        
        guard let task = self.listFilesTask.object(forKey: folder.fullServicePath) as? ODURLSessionDataTask else {
            return false
        }
        task.cancel()
        return true
    }
    
    func downloadFile(file: NXFileBase, filePath: String, id: Int) -> Bool {
        guard isAuthed == true,
            file is NXFile else {
            return false
        }
        
        guard let task = self.client?.drive().items(file.fullServicePath).contentRequest().download(completion: {url, response, error in
            self.downloadFinished(file: file, src: url, dst: URL(fileURLWithPath: filePath), error: error as NSError?)}) else {
            return false
        }
        
        //FIXME: use downloadContext array
        task.progress.totalUnitCount = file.size
        task.progress.addObserver(self, forKeyPath: "fractionCompleted", options: .new, context: &self.downloadContext)
        
        downloadTask = task
        downloadOrUploadId = id
        
        return true
    }
    
    func rangeDownloadFile(file: NXFileBase, length: Int, filePath: String, id: Int) -> Bool {
        guard isAuthed == true,
            file is NXFile else {
                return false
        }
       
        let range = NSMakeRange(0, length)
        
        guard let task = self.client?.drive().items(file.fullServicePath).contentRequest().rangeDownload(range: range, completionHandler: {url, response, error in
            self.rangeDownloadFinished(file: file, src: url, dst: URL(fileURLWithPath: filePath), length: length, error: error as? NSError)}) else {
            return false
        }
        
        //FIXME: use rangeDownloadContext array
        task.progress.totalUnitCount = file.size
        task.progress.addObserver(self, forKeyPath: "fractionCompleted", options: .new, context: &self.rangeDownloadContext)
        
        downloadTask = task
        downloadOrUploadId = id
        
        return true
    }
    
    func deleteFileFolder(file: NXFileBase) -> Bool {
        guard isAuthed == true else {
            return false
        }
        if self.client?.drive().items(file.fullServicePath).request().delete(completion: {error in
            self.deleteFileFinished(file: file, error: error as NSError?)
        }) == nil {
            return false
        }
        return true
    }
    
    func addFolder(folderName: String, parentFolder: NXFileBase) -> Bool {
        guard isAuthed == true,
            parentFolder is NXFolder else {
            return false
        }
        if parentFolder.isRoot{
            parentFolder.fullPath = "/"
            parentFolder.fullServicePath = NXOneDrive.NXONEDRIVE_ROOT
        }
        let folder = ODItem()
        folder.name = folderName
        folder.folder = ODFolder()
        
        guard self.client?.drive().items(parentFolder.fullServicePath).children().request().add(folder, withCompletion: {item, error in
            self.createFolderFinished(item: item, folderName: folderName, parentFolder: parentFolder, error: error as NSError?)}) != nil else {
            return false
        }
        return true
    }
    
    func uploadFile(filename: String, folder: NXFileBase, srcPath: String, fileSource: NXFileBase? = nil, id: Int) -> Bool {
        guard isAuthed == true,
            folder is NXFolder else {
            return false
        }
        
        if folder.isRoot{
            folder.fullPath = "/"
            folder.fullServicePath = NXOneDrive.NXONEDRIVE_ROOT
        }
        
        let srcUrl = URL(fileURLWithPath: srcPath)
        
        guard let task = self.client?.drive().items(folder.fullServicePath).item(byPath: filename).contentRequest().upload(fromFile: srcUrl, completion: {item, error in
            self.uploadFileFinished(folder: folder, srcPath: srcPath, error: error as NSError?)}) else {
            return false
        }
        
        do{
            let fileinfo = try FileManager.default.attributesOfItem(atPath: srcPath)
            task.progress.totalUnitCount = Int64(fileinfo[FileAttributeKey.size] as! Int64)
            task.progress.addObserver(self, forKeyPath: "fractionCompleted", options: .new, context: &self.uploadContext)
        }
        catch{
            return false
        }
        
        uploadTask = task
        downloadOrUploadId = id
        
        return true
    }
    
    func cancelDownloadOrUpload(id: Int) {
        guard isAuthed == true else {
            return
        }
        
        guard downloadOrUploadId == id else {
            return
        }
        
        downloadTask?.cancel()
        uploadTask?.cancel()
    }
    
    func updateFile(srcPath: String, dstFile: NXFileBase) -> Bool {
        guard isAuthed == true,
            dstFile is NXFile else {
                return false
        }
        let srcUrl = URL(fileURLWithPath: srcPath)
        
        guard let task = self.client?.drive().items(dstFile.fullServicePath).contentRequest().upload(fromFile: srcUrl, completion: {item, error in
            self.updateFileFinished(dstFile: dstFile, srcPath: srcPath, error: error as NSError?)}) else {
            return false
        }
        do{
            let fileinfo = try FileManager.default.attributesOfItem(atPath: srcPath)
            task.progress.totalUnitCount = Int64(fileinfo[FileAttributeKey.size] as! Int64)
            
            //FIXME: use updateContext array
            task.progress.addObserver(self, forKeyPath: "fractionCompleted", options: .new, context: &self.updateContext)
        }
        catch{
            return false
        }
        
        let key = getUpdateTicketKey(srcPath: srcPath, dstFile: dstFile)
        self.updateFileTask.setObject(task, forKey: key as NSCopying)
        self.updateSrcDestPath.setObject(srcPath, forKey: key as NSCopying)
        self.updateFile.setObject(dstFile, forKey: key as NSCopying)
        return true

    }
    
    func cancelUpdateFile(srcPath: String, dstFile: NXFileBase) -> Bool {
        guard isAuthed == true else {
            return false
        }
        let key = getUpdateTicketKey(srcPath: srcPath, dstFile: dstFile)
        guard let task = self.updateFileTask.object(forKey: key) as? ODURLSessionUploadTask else {
            return false
        }
        task.cancel()
        return true
    }
    
    func getMetaData(file: NXFileBase) -> Bool {
        guard isAuthed == true,
            file.isRoot == false else {
            return false
        }
        
        guard let task = self.client?.drive().items(file.fullServicePath).request().getWithCompletion({item, error in
            self.getMetaFinished(item: item, file: file, error: error as NSError?)}) else {
            return false
        }
        self.metaDataTask.setObject(task, forKey: file.fullServicePath as NSCopying)
        return true
    }
    
    func cancelGetMetaData(file: NXFileBase) -> Bool {
        guard isAuthed == true else {
            return false
        }
        
        guard let task = self.metaDataTask.object(forKey: file.fullServicePath) as? ODURLSessionDataTask else {
            return false
        }
        task.cancel()
        return true
    }
    
    func setDelegate(delegate: NXServiceOperationDelegate) {
        self.delegate = delegate
    }
    
    func isProgressSupported() -> Bool {
        return true
    }
    
    func setAlias(alias: String) {
        self.alias = alias
    }
    
    func getServiceAlias() -> String {
        return self.alias
    }
    
    func getUserInfo() -> Bool {
        guard isAuthed == true else {
            return false
        }
        
        guard let task = self.client?.drive().request().getWithCompletion({drive, error in
            self.getUserInfoFinished(drive: drive, error: error as NSError?)}) else{
            return false
        }
        self.userInfoTask = task
        return true
    }
    
    func cancelGetUserInfo() -> Bool {
        guard isAuthed == true,
            let userInfoTast = self.userInfoTask else{
            return false
        }
        userInfoTast.cancel()
        return true
    }
    
    //MARK: OneDrive callback handler
    private func getFilesFinished(files: NSArray?, error: NSError?){
        let parentFolder = self.enumFolderStack.lastObject as! NXFolder
        self.enumFolderStack.removeLastObject()
        self.listFilesTask.removeObject(forKey: parentFolder.fullServicePath)
        if let error = error {
            let retError = self.convert2NxError(error: error)
            self.delegate?.getFilesFinished?(folder: parentFolder, files: nil, error: retError)
        }
        else if let files = files {
            let newList = NSMutableArray()
            for item in files {
                guard let odItem = item as? ODItem else {
                    continue
                }
                var nxfile: NXFileBase!
                if odItem.file != nil{
                    nxfile = NXFile()
                }
                else {
                    nxfile = NXFolder()
                }
                self.fetchFile(nxfile: nxfile, item: odItem, parent: parentFolder)
                nxfile.isOffline = false
                nxfile.isFavorite = false
                nxfile.parent = parentFolder
                newList.add(nxfile)
            }
            NXCommonUtils.updateFolderChildren(folder: parentFolder, newFileList: newList)
            self.delegate?.getFilesFinished?(folder: parentFolder, files: parentFolder.getChildren(), error: nil)
        }
        else {
            self.delegate?.getFilesFinished?(folder: parentFolder, files: nil, error: nil)
        }
    }
    
    private func recurGetFilesFinished(files : NSArray?, error : NSError?){
        let parentFolder = self.enumFolderStack.lastObject as! NXFolder
        self.enumFolderStack.removeLastObject()
        self.listFilesTask.removeObject(forKey: parentFolder.fullServicePath)
        if let files = files {
            files.enumerateObjects({item, index, stop in
                guard let odItem = item as? ODItem else {
                    return
                }
                var nxfile: NXFileBase!
                if odItem.file != nil{
                    nxfile = NXFileBase()
                }
                else {
                    nxfile = NXFolder()
                }
                self.fetchFile(nxfile: nxfile, item: odItem, parent: parentFolder)
                nxfile.parent = parentFolder
                
                if nxfile is NXFile{
                    self.recursiveFileList.add(nxfile)
                }
                else if nxfile is NXFolder{
                    self.enumFolderStack.add(nxfile)
                }
            })
        }
        if self.enumFolderStack.count == 0 {
            self.delegate?.getAllFiles?(servicePath: self.curFolder.fullServicePath ,files: self.recursiveFileList, error: nil)
            self.recursiveFileList.removeAllObjects()
            self.enumFolderStack.removeAllObjects()
        }
        else{
            let folder = self.enumFolderStack.lastObject as! NXFolder
            guard let task = self.client?.drive().items(folder.fullServicePath).children().request().getWithCompletion({response, nextRequest, error in
                if error == nil{
                    self.recurGetFilesFinished(files: response?.value as NSArray?, error: nil)
                }
                else{
                    self.recurGetFilesFinished(files: nil, error: error as NSError?)
                }
            }) else {
                self.delegate?.getAllFiles?(servicePath: self.curFolder.fullServicePath ,files: self.recursiveFileList, error: nil)
                self.recursiveFileList.removeAllObjects()
                self.enumFolderStack.removeAllObjects()
                return
            }
            self.listFilesTask.setObject(task, forKey: folder.fullServicePath as NSCopying)
        }
    }
    
    func downloadFinished(file: NXFileBase, src: URL?, dst: URL, error: NSError?){
        downloadTask?.progress.removeObserver(self, forKeyPath: "fractionCompleted", context: &downloadContext)
        
        if let error = error {
            var retError: NSError?
            if error.code == -999 {
                retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
            } else {
                retError = self.convert2NxError(error: error)
            }
            
            self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
        }
        else {
            do{
                if FileManager.default.fileExists(atPath: dst.path) {
                    try FileManager.default.removeItem(at: dst)
                }
                
                guard let src = src else {
                    let retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE, error: nil)
                    self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
                    return
                }
                
                try FileManager.default.moveItem(at: src, to: dst)

                self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: nil)
            }
            catch{
                let retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE, error: nil)
                self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
            }
        }
    }
    
    func rangeDownloadFinished(file: NXFileBase, src: URL?, dst: URL, length: Int, error: NSError?){
        downloadTask?.progress.removeObserver(self, forKeyPath: "fractionCompleted", context: &rangeDownloadContext)
        
        if let error = error {
            var retError: NSError?
            if error.code == -999 {
                retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
            } else {
                retError = self.convert2NxError(error: error)
            }
            
            self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
        }
        else {
            do{
                if FileManager.default.fileExists(atPath: dst.path) {
                    try FileManager.default.removeItem(at: dst)
                }
            
                guard let src = src,
                    let content = try? Data(contentsOf: src),
                    content.count >= length else {
                        let retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_RENDER_FILE_FAILED.rawValue, userInfo: nil)
                        self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
                        return
                }
                
                try FileManager.default.moveItem(at: src, to: dst)
                
                self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: nil)
            }
            catch{
                let retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE, error: nil)
                self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
            }
        }
    }

    func deleteFileFinished(file: NXFileBase?, error: NSError?) {
        var retError: NSError?
        if let error = error {
            retError = self.convert2NxError(error: error)
        }
        self.delegate?.deleteFileFolderFinished?(servicePath: file?.fullServicePath, error: retError)
    }
    
    func createFolderFinished(item: ODItem?, folderName: String?, parentFolder: NXFileBase?, error: NSError?){
        let folder = NXFolder()
        var retError: NSError?
        if let error = error {
            retError = self.convert2NxError(error: error)
        }
        else if let item = item,
            let parentFolder = parentFolder {
            self.fetchFile(nxfile: folder, item: item, parent: parentFolder)
        }
        self.delegate?.addFolderFinished?(folderName: folderName, parentServicePath: parentFolder?.fullServicePath, error: retError)
    }
    
    func uploadFileFinished(folder: NXFileBase, srcPath: String, error: NSError?) {
        uploadTask?.progress.removeObserver(self, forKeyPath: "fractionCompleted", context: &self.uploadContext)
        
        var retError: NSError?
        if let error = error {
            if error.code == -999 {
                retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
            } else {
                retError = self.convert2NxError(error: error)
            }
        }
        self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
    }
    
    func updateFileFinished(dstFile: NXFileBase, srcPath: String, error: NSError?) {
        let key = getUpdateTicketKey(srcPath: srcPath, dstFile: dstFile)
        if let task = self.updateFileTask.object(forKey: key) as? ODURLSessionUploadTask {
            task.progress.removeObserver(self, forKeyPath: "fractionCompleted", context: &self.updateContext)
        }
        self.updateFileTask.removeObject(forKey: key)
        self.updateSrcDestPath.removeObject(forKey: key)
        self.updateFile.removeObject(forKey: key)
        var retError: NSError?
        if let error = error {
            retError = self.convert2NxError(error: error)
        }
        self.delegate?.updateFileFinished?(srcPath: srcPath, fileServicePath: dstFile.fullServicePath, error: retError)
    }
    
    func getMetaFinished(item: ODItem?, file: NXFileBase, error: NSError?) {
        self.metaDataTask.removeObject(forKey: file.fullServicePath)
        if let error = error {
            let retError = self.convert2NxError(error: error)
            if self.delegate != nil && (self.delegate?.responds(to: #selector(self.delegate?.getMetaDataFinished(servicePath:error:))))! {
                self.delegate?.getMetaDataFinished!(servicePath: file.fullServicePath, error: retError)
            }
        }
        else if let item = item {
            guard let parent = file.parent else {
                let retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE, error: nil)
                self.delegate?.getMetaDataFinished?(servicePath: file.fullServicePath, error: retError)
                return
            }
            self.fetchFile(nxfile: file, item: item, parent: parent)
            self.delegate?.getMetaDataFinished?(servicePath: file.fullServicePath, error: nil)
        }
        else {
            self.delegate?.getMetaDataFinished?(servicePath: file.fullServicePath, error: nil)
        }
    }
    
    func getUserInfoFinished(drive: ODDrive?, error: NSError?){
        if let error = error {
            let retError = self.convert2NxError(error: error)
            self.delegate?.getUserInfoFinished!(username: nil, email: nil, totalQuota: nil, usedQuota: nil, error: retError)
        }
        else if let total = drive?.quota.total,
            let used = drive?.quota.used {
            self.delegate?.getUserInfoFinished?(username: drive?.owner.user.displayName, email: drive?.owner.user.displayName, totalQuota: NSNumber(value: total), usedQuota: NSNumber(value: used), error: nil)
        }
        else {
            self.delegate?.getUserInfoFinished?(username: drive?.owner.user.displayName, email: drive?.owner.user.displayName, totalQuota: nil, usedQuota: nil, error: nil)
        }
    }
    
    //MARK: key vaule observe
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &self.downloadContext {
            if let progress = object as? Progress {
                self.delegate?.updateProgress?(id: downloadOrUploadId!,progress: Float(progress.fractionCompleted))
                return
            }
        }
        else if context == &self.rangeDownloadContext {
            if let progress = object as? Progress {
                self.delegate?.updateProgress?(id: downloadOrUploadId!,progress: Float(progress.fractionCompleted))
                return
            }
        }
        else if context == &self.uploadContext{
            if let progress = object as? Progress {
                self.delegate?.updateProgress?(id: downloadOrUploadId!,progress: Float(progress.fractionCompleted))
                return
            }
        }
        else if context == &self.updateContext {
            for item in self.updateFileTask {
                if let progress = object as? Progress,
                    let task = item.value as? ODURLSessionUploadTask,
                    let taskProgress = task.progress,
                    progress == taskProgress,
                    let srcPath = self.updateSrcDestPath.object(forKey: item.key) as? String,
                    let file = self.updateFile.object(forKey: item.key) as? NXFileBase {
                    self.delegate?.updateFileProgress?(progress: Float(progress.fractionCompleted), srcPath: srcPath, fileServicePath: file.fullServicePath)
                    return
                }
            }
        }
        else {
             super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    //MARK: Private method
    private func fetchFile(nxfile: NXFileBase, item: ODItem, parent: NXFileBase){
        nxfile.name = item.name
        if let fullPath = NSURL(fileURLWithPath: parent.fullPath).appendingPathComponent(item.name)?.path {
            nxfile.fullPath = fullPath
            if nxfile is NXFolder {
                nxfile.fullPath.append("/")
            }
        }
        nxfile.fullServicePath = item.id
        nxfile.serviceAccountId = self.userId
        nxfile.serviceAlias = self.getServiceAlias()
        nxfile.lastModifiedDate = item.lastModifiedDateTime as NSDate
  //      let date = DateFormatter.localizedString(from: item.lastModifiedDateTime, dateStyle: .short, timeStyle: .full)
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeString = formatter.string(from: item.lastModifiedDateTime)
        
        nxfile.lastModifiedTime = timeString
        nxfile.size = item.size
        nxfile.serviceType = NSNumber(value: ServiceType.kServiceOneDrive.rawValue)
        nxfile.boundService = parent.boundService
        
    }
    
    private func convert2NxError(error: NSError) -> NSError?{
        var retError: NSError? = error
        if error.code == ONEDRIVE_ERRORCODE.ONEDRIVE_ERRORCODE_CANCEL.rawValue{
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_CANCEL, error: error)
        }
        else if error.code == ONEDRIVE_ERRORCODE.ONEDRIVE_ERRORCODE_NOTFOUND.rawValue {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_NOSUCHFILE, error: error)
        }
        else if error.code < 0 && error.code != NSURLErrorCancelled{
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_TRANS_BYTES_FAILED, error: error)
        }
        else if error.code == 404 {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_NOSUCHFILE, error: error)
        }
        else if error.code == 401 {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_AUTHFAILED, error: error)
        }
        else if error.code == 507 {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_DRIVE_STORAGE_EXCEEDED, error: error)
        }
        if error.domain == OD_AUTH_ERROR_DOMAIN {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_AUTHFAILED, error: error)
        }
        return retError
    }
    
    private func getUploadTicketKey(srcPath: String, folder: NXFileBase) -> String {
        return folder.fullServicePath.appending(srcPath)
    }
    
    private func getUpdateTicketKey(srcPath: String, dstFile: NXFileBase) -> String {
        return dstFile.fullServicePath.appending(srcPath)
    }
}

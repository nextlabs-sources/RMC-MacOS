//
//  NXSkyDrmBox.swift
//  skyDRM
//
//  Created by pchen on 13/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

// MARK: - NXServiceOperation

extension NXSkyDrmBox: NXServiceOperation {
    
    func getFiles(folder: NXFileBase) -> Bool
    {
        if folder.isRoot {
            folder.fullServicePath = "/"
        }
        
        let completion: NXMyDriveRestProviderOperation.getFilesCompletion = {
            items, error in
            
            if let items = items {
                let filelist = items.map() { item -> NXFileBase in
                    let file = (item.folder) ? NXFolder() : NXFile()
                    file.refreshDate = Date()
                    self.fetchFileInfo(from: item, to: file)
                    file.parent = folder
                    file.boundService = folder.boundService
                    return file
                }
                
                NXCommonUtils.updateFolderChildren(folder: folder, newFileList: filelist as NSArray)
            }
            
            DispatchQueue.main.async {
                self.delegate?.getFilesFinished?(folder: folder, files: folder.getChildren(), error: error as NSError?)
            }
        }
        
        restProvider.getFiles(folder.fullServicePath, recursive: false, completion: completion)
        
        return true
    }
    
    // TODO: recursive = true
    func getAllFilesInFolder(folder: NXFileBase) -> Bool
    {
        return false
    }
    
    func cancelGetFiles(folder: NXFileBase) -> Bool {
        
        return restProvider.cancelGetFiles(folder.fullServicePath)
    }
    
    func downloadFile(file: NXFileBase, filePath: String, id: Int) -> Bool {
        let progressCompletion: NXMyDriveRestProviderOperation.fileProgressCompletion = {
            path, progress in
            self.delegate?.updateProgress?(id: self.downloadOrUploadId!, progress: Float(progress))
        }
        
        let completion: NXMyDriveRestProviderOperation.downloadFileCompletion = {
            servicePath, cachePath, error in
            if (error as NSError?)?.code == -999 {
                let retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
                self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: retError)
            } else {
                self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: error as NSError?)
            }
        }
        
        restProvider.downloadFile(from: file.fullServicePath, to: filePath, size: Int(file.size), progressCompletion: progressCompletion, completion: completion)
        
        iDownloadUploadAction = 0
        fullServicePath = file.fullServicePath
        downloadOrUploadId = id
        
        return true
    }
    
    func rangeDownloadFile(file: NXFileBase, length: Int, filePath: String, id: Int) -> Bool {
        let progressCompletion: NXMyDriveRestProviderOperation.fileProgressCompletion = {
            path, progress in
            self.delegate?.updateProgress?(id: self.downloadOrUploadId!, progress: Float(progress))
        }
        
        let completion: NXMyDriveRestProviderOperation.rangeDownloadFileCompletion = {
            servicePath, data, error in
            if error != nil {
                if (error as NSError?)?.code == -999 {
                    let retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
                    self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: retError)
                } else {
                    self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: error as NSError?)
                }
            } else {
                do{
                    try data?.write(to: URL(fileURLWithPath: filePath, isDirectory: false))
                    self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: nil)
                }
                catch{
                    let retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_FILE_ACCESS_DENIED, error: nil)
                    self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: retError)
                }
            }
        }
        
        restProvider.rangeDownloadFile(from: file.fullServicePath, start: 0, size: length, progressCompletion: progressCompletion, completion: completion)
        
        iDownloadUploadAction = 1
        fullServicePath = file.fullServicePath
        downloadOrUploadId = id
        
        return true

    }
    
    func deleteFileFolder(file : NXFileBase) -> Bool {
        let completion: NXMyDriveRestProviderOperation.deletePathCompletion = {
            path, error in
            DispatchQueue.main.async {
                self.delegate?.deleteFileFolderFinished?(servicePath: path, error: error as NSError?)
            }
        }
        restProvider.deletePath(file.fullServicePath, completion: completion)
        
        return true
    }
    
    func addFolder(folderName : String, parentFolder : NXFileBase) -> Bool {
        
        var folderPath:String? = ""
        if parentFolder.isRoot {
            folderPath = "/"
        }
        else
        {
            folderPath = parentFolder.fullServicePath
        }
       
        let completion: NXMyDriveRestProviderOperation.createFolderCompletion = {
            _, error in
            
            DispatchQueue.main.async {
                self.delegate?.addFolderFinished?(folderName: folderName, parentServicePath: folderPath, error: error as NSError?)
            }
        }
        restProvider.createFolder(name: folderName, toFolder: folderPath!, completion: completion)
        
        return true
    }
    
    func uploadFile(filename: String, folder: NXFileBase, srcPath: String, fileSource: NXFileBase? = nil, id: Int) -> Bool {
        let progressCompletion: NXMyDriveRestProviderOperation.fileProgressCompletion = {
            path, progress in
            self.delegate?.updateProgress?(id: self.downloadOrUploadId!, progress: Float(progress))
        }
        
        let completion: NXMyDriveRestProviderOperation.uploadFileCompletion = {
            fromPath, toPath, item, error in
            if (error as NSError?)?.code == -999 {
                let retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
                self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: retError)
            } else {
                if let backendError = error as? BackendError {
                    switch backendError {
                    case .failResponse(let reason):
                        if reason == "Drive Storage Exceeded." {
                            let retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_DRIVE_STORAGE_EXCEEDED.rawValue, userInfo: nil)
                            self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: retError)
                        } else {
                            self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: error as NSError?)
                        }
                        return
                    default:
                        self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: error as NSError?)
                        return
                    }
                } else {
                    self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: error as NSError?)
                }
            }
        }
        
        restProvider.uploadfile(filename: filename, fromPath: srcPath, toFolder: folder.fullServicePath, progressCompletion: progressCompletion, completion: completion)
        
        iDownloadUploadAction = 2
        uploadSrcPath = srcPath
        fullServicePath = folder.fullServicePath
        downloadOrUploadId = id
        
        return true
    }
    
    func cancelDownloadOrUpload(id: Int) {
        guard downloadOrUploadId == id else {
            return
        }
        
        if iDownloadUploadAction == 0 {
            _ = restProvider.cancelDownload(servicePath: fullServicePath!, toFolder: nil)
        } else if iDownloadUploadAction == 1 {
            _ = restProvider.cancelRangeDownload(servicePath: fullServicePath!)
        } else if iDownloadUploadAction == 2 {
            _ = restProvider.cancelUploadFile(srcPath: uploadSrcPath!, toFolder: fullServicePath!)
        }
    }
    
    func updateFile(srcPath: String, dstFile: NXFileBase) -> Bool {
        
        return false

    }
    
    func cancelUpdateFile(srcPath: String, dstFile: NXFileBase) -> Bool {
        return false
    }
    
    func getMetaData(file : NXFileBase) -> Bool {
        return false
    }
    
    func cancelGetMetaData(file : NXFileBase) -> Bool {
        return false
    }
    
    func setDelegate(delegate : NXServiceOperationDelegate) {
        self.delegate = delegate
    }
    
    func isProgressSupported() -> Bool {
        return false
    }
    
    func setAlias(alias : String) {
        self.alias = alias
    }
    
    func getServiceAlias() -> String {
        guard let unnoneAlias = alias else {
            return ""
        }
        return unnoneAlias
    }
    
    func getUserInfo() -> Bool {
        let completion: NXMyDriveRestProviderOperation.getUserInfoCompletion = {
            totalQuota, usedQuota, vaultQuota, error in
            let convertToNumber: (Int64?) -> NSNumber? = {
                value in
                guard let value = value else {
                    return nil
                }
                return NSNumber(value: value)
            }
            
            self.delegate?.getUserInfoFinishedExtraData?(username: nil, email: nil, totalQuota: convertToNumber(totalQuota), usedQuota: convertToNumber(usedQuota), property: convertToNumber(vaultQuota), error: nil)
        }
        
        restProvider.getUserInfo(completion: completion)
        return true
    }
    
    func cancelGetUserInfo() -> Bool {
        return false
    }
}

class NXSkyDrmBox: NSObject {
    
    init(withUserID userId: String, ticket: String) {
        self.restProvider = NXMyDriveRestProvider(withUserID: userId, ticket: ticket)
        self.userId = userId
        
        super.init()
    }
    
    fileprivate var restProvider: NXMyDriveRestProvider
    fileprivate var userId: String
    fileprivate var alias: String?
    fileprivate weak var delegate: NXServiceOperationDelegate?
    
    fileprivate var iDownloadUploadAction : Int? = nil
    fileprivate var uploadSrcPath : String? = nil
    fileprivate var fullServicePath : String? = nil
    fileprivate var downloadOrUploadId : Int? = nil
    
    fileprivate func fetchFileInfo(from item: NXMyDriveFileItem, to file: NXFileBase) {
        file.isOffline = false
        file.isFavorite = false
        if let path = item.pathDisplay {
            file.fullPath = path
        }
        if let pathId = item.path {
            file.fullServicePath = pathId
        }
        if let filename = item.name {
            file.name = filename
        }
        if let lastModified = item.lastModified, let last = Int64(lastModified) {
            
            let minSecondsToSecond: Int64 = 1000
            let interval = last/minSecondsToSecond
            let lastmodifiedDate = Date.init(timeIntervalSince1970: TimeInterval(interval))
            let dateStr = DateFormatter.localizedString(from: lastmodifiedDate, dateStyle: .short, timeStyle: .full)
            file.lastModifiedDate = lastmodifiedDate as NSDate
            file.lastModifiedTime = dateStr
        }
        if let size = item.size, let fileSize = Int64(size) {
            file.size = fileSize
        }
        
        file.isRoot = false
        file.serviceAccountId = self.userId
        
        file.serviceType = NSNumber.init(value: ServiceType.kServiceSkyDrmBox.rawValue)
        file.serviceAlias = getServiceAlias()
    }
}




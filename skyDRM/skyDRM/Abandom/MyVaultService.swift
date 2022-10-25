//
//  MyVaultService.swift
//  skyDRM
//
//  Created by pchen on 25/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

extension MyVaultService: NXServiceOperation {

    func getFiles(folder: NXFileBase) -> Bool {
        return getAllFilesInFolder(folder: folder)
    }
    
    func getAllFilesInFolder(folder: NXFileBase) -> Bool  {
        let allFilesFilterModel = NXMyVaultListParModel(page: "1", size: String(Constant.maxSize), filterType: .allFiles, sortOptions: [.createTime(isAscend: true)], searchString: nil)
        
        // TODO: no cache now
        return getFiles(inFolder: folder, withFilter: allFilesFilterModel, shouldReadCache: nil)
    }
    
    func getMetaData(file: NXFileBase) -> Bool {
        guard
            let file = file as? NXNXLFile,
            let duid = file.getNXLID()
            else { return false }
        
        let parameter = [RequestParameter.url: [Constant.kDuid: duid],
                         RequestParameter.body: [Constant.kPathId: file.fullServicePath]]
        let completion: (Any?, Error?) -> Void = {
            response ,error in
            
            if error == nil, let response = response as? MyVaultResponse.GetMetadataResponse {
                self.fetchFileInfo(from: response.file, to: file)
            }
            
            self.delegate?.getMetaDataFinished?(servicePath: file.fullServicePath, error: error as NSError?)
        }
        
        let api = MyVaultAPI(withType: .getMetadata)
        api.sendRequest(withParameters: parameter, completion: completion)
        
        return true
    }
    
    func deleteFileFolder(file: NXFileBase) -> Bool {
        guard
            let file = file as? NXNXLFile,
            let duid = file.getNXLID()
            else { return false }
        
        let parameter = [RequestParameter.url: [Constant.kDuid: duid],
                         RequestParameter.body: [Constant.kPathId: file.fullServicePath]]
        let completion: (Any?, Error?) -> Void = {
            _, error in
            self.delegate?.deleteFileFolderFinished?(servicePath: file.fullServicePath, error: error as NSError?)
        }
        let api = MyVaultAPI(withType: .deleteFile)
        api.sendRequest(withParameters: parameter, completion: completion)
        
        return true
    }

    func uploadFile(filename: String, folder: NXFileBase, srcPath: String, fileSource: NXFileBase?, id: Int) -> Bool {
        let api = MyVaultAPI(withType: .uploadFile)
        
        downloadOrUploadRestOperation = NXMyVaultRestOperation(withRestAPI: api, from: srcPath, toFolder: folder.fullServicePath)
        
        var srcPathId = ""
        if fileSource != nil {
            srcPathId = (fileSource?.fullServicePath)!
        }
        
        var srcPathDisplay = filename
        if fileSource != nil {
            srcPathDisplay = (fileSource?.fullPath)!
            if srcPathDisplay.isEmpty {
                srcPathDisplay = (fileSource?.localPath)!
            }
        }
        
        var srcRepoId = ""
        if fileSource != nil {
            srcRepoId = (fileSource?.boundService?.repoId) ?? srcRepoId
        }
        
        var srcRepoName = "local"
        if fileSource != nil {
            srcRepoName = (fileSource?.boundService?.serviceAlias) ?? srcRepoName
        }
        
        var srcRepoType = "local"
        if fileSource != nil,
            let serviceType = fileSource?.boundService?.serviceType {
            srcRepoType = String(serviceType)
        }
        
        let srcInfo = [Constant.kSrcPathId: srcPathId, Constant.kSrcPathDisplay: srcPathDisplay, Constant.kSrcRepoId: srcRepoId, Constant.kSrcRepoName: srcRepoName, Constant.kSrcRepoType: srcRepoType]
        
        let targetFileName: String = {
            return URL(fileURLWithPath: srcPath).lastPathComponent
        }()
        
        let url = URL(fileURLWithPath: srcPath)
        guard let date = try? Data(contentsOf: url) else {
            Swift.print("cannot get upload data")
            return false
        }
        
        let parameters: [String: Any] = [RequestParameter.name: targetFileName, RequestParameter.data: date, RequestParameter.body: srcInfo]
        
        let progress: (Double) -> Void = {
            progress in
            self.delegate?.updateProgress?(id: self.downloadOrUploadId!, progress: Float(progress))
        }
        
        let completion: (Any?, Error?) -> Void = {
            _, error in
            
            if (error as NSError?)?.code == -999 {
                let retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
                self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: retError)
            } else {
                if let backendError = error as? BackendError {
                    switch backendError {
                    case .failResponse(let reason):
                        if reason == "Vault Storage Exceeded." {
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
        
        api.uploadFile(withParameters: parameters, progress: progress, completion: completion)
        
        downloadOrUploadId = id
        
        return true
    }
    
    func updateFile(srcPath: String, dstFile: NXFileBase) -> Bool {
        return false
    }

    func cancelUpdateFile(srcPath: String, dstFile: NXFileBase) -> Bool {
        return false
    }
    
    func downloadFile(file: NXFileBase, filePath: String, id: Int) -> Bool {
        guard let file = file as? NXNXLFile else {
            return false
        }
        
        let api = MyVaultAPI(withType: .downloadFile)
        
        downloadOrUploadRestOperation = NXMyVaultRestOperation(withRestAPI: api, from: file.fullServicePath, toFolder: filePath)
        
        let parameters: [String: Any] = [RequestParameter.body: [Constant.kPathId: file.fullServicePath, Constant.kStart: 0, Constant.kLength: file.size, Constant.kForViewer: true]]
        
        let progressHandler: (Double) -> Void = {
            progress in
            self.delegate?.updateProgress?(id: self.downloadOrUploadId!, progress: Float(progress))
        }
        
        let completion: (Any?, Error?) -> Void = {
            _, error in
            
            if (error as NSError?)?.code == -999 {
                let retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
                self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: retError)
            } else {
                self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: error as NSError?)
            }
        }
        
        api.downloadFile(withParameters: parameters, destination: filePath, progress: progressHandler, completion: completion)
        
        downloadOrUploadId = id
        
        return true
    }
    
    func rangeDownloadFile(file: NXFileBase, length: Int, filePath: String, id: Int) -> Bool {
        return false
    }
    
    func cancelDownloadOrUpload(id: Int) {
        guard downloadOrUploadId == id else {
            return
        }
        
        _ = downloadOrUploadRestOperation?.cancel()
    }
    
    func setDelegate(delegate: NXServiceOperationDelegate) {
        self.delegate = delegate
    }
    
    func isProgressSupported() -> Bool {
        return true
    }
    
    func cancelGetFiles(folder: NXFileBase) -> Bool {
        return false
    }
    
    func addFolder(folderName: String, parentFolder: NXFileBase) -> Bool {
        return false
    }
    
    func cancelGetMetaData(file: NXFileBase) -> Bool {
        return false
    }
    
    func setAlias(alias: String) {
    }
    
    func getServiceAlias() -> String {
        return ""
    }
    
    func getUserInfo() -> Bool {
        return false
    }
    
    func cancelGetUserInfo() -> Bool {
        return false
    }
}

extension MyVaultService {
    func getFiles(inFolder folder: NXFileBase, withFilter filter: NXMyVaultListParModel, shouldReadCache: Bool?) -> Bool {
        let parameter = [RequestParameter.filter: filter]
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            if error == nil, let response = response as? MyVaultResponse.ListFileResponse {
                let files = response.files.map() {
                    item -> NXNXLFile in
                    let file = NXNXLFile()
                    self.fetchFileInfo(from: item, to: file)
                    file.parent = folder
                    file.boundService = folder.boundService
                    return file
                }
                
                folder.removeAllChildren()
                for file in files { folder.addChild(child: file) }
            }
    
            self.delegate?.getFilesFinished?(folder: folder, files: folder.getChildren(), error: error as NSError?)
        }
        
        let api = MyVaultAPI(withType: .listFile)
        api.sendRequest(withParameters: parameter, completion: completion)
        
        return true
    }
}

class MyVaultService: NSObject {
    fileprivate struct Constant {
        static let maxSize = 1000000
        static let kSrcPathId = "srcPathId"
        static let kSrcPathDisplay = "srcPathDisplay"
        static let kSrcRepoId = "srcRepoId"
        static let kSrcRepoName = "srcRepoName"
        static let kSrcRepoType = "srcRepoType"
        static let kPathId = "pathId"
        static let kStart = "start"
        static let kLength = "length"
        static let kForViewer = "forViewer"
        static let kDuid = "duid"
    }
    
    init(withUserID userID: String, ticket: String) {
        MyVaultAPI.setting(withUserID: userID, ticket: ticket)
    }
    
    weak var delegate: NXServiceOperationDelegate?
    
    fileprivate var downloadOrUploadRestOperation : NXMyVaultRestOperation? = nil
    fileprivate var downloadOrUploadId : Int? = nil
    
    fileprivate func fetchFileInfo(from item: NXMyVaultFileItem, to file: NXNXLFile) {
        file.fullServicePath = item.pathId ?? ""
        file.fullPath = item.pathDisplay ?? ""
        file.repoId = item.repoId ?? ""
        file.lastModifiedDate = NSDate(timeIntervalSince1970: (Double(item.sharedOn)/1000))
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        file.lastModifiedTime = formatter.string(from: file.lastModifiedDate as Date)
        file.name = item.name ?? ""
        file.sharedWith = item.sharedWith
        file.setNXLID(nxlId: item.duid ?? "")
        file.isRevoked = item.isRevoked
        file.isDeleted = item.isDeleted
        file.isShared = item.isShared
        file.size = item.size
        file.customMetadata = item.customMetadata
    }
    
    fileprivate func fetchFileInfo(from item: NXMyVaultDetailFileItem, to file: NXNXLFile) {
        file.name = item.name ?? ""
        file.recipients = item.recipients
        file.fileLink = item.fileLink
        file.protectedOn = item.protectedOn
        file.sharedOn = item.sharedOn
        file.rights = item.rights
    }
}


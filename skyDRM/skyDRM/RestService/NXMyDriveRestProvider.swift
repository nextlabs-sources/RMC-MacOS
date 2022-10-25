//
//  SDClient.swift
//  skyDRM
//
//  Created by pchen on 13/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol NXMyDriveRestProviderOperation {
    func getFiles(_ path: String, recursive: Bool, completion: @escaping getFilesCompletion)
    func cancelGetFiles(_ path: String) -> Bool
    func downloadFile(from path: String, to destPath: String, size: Int, progressCompletion: @escaping fileProgressCompletion, completion: @escaping downloadFileCompletion)
    func rangeDownloadFile(from path: String, start: Int, size: Int, progressCompletion: @escaping fileProgressCompletion, completion: @escaping rangeDownloadFileCompletion)
    func cancelDownload(servicePath path: String, toFolder folderPath: String?) -> Bool
    func cancelRangeDownload(servicePath path: String) -> Bool
    func uploadfile(filename: String, fromPath srcPath: String, toFolder folderPath: String, progressCompletion: @escaping fileProgressCompletion, completion: @escaping uploadFileCompletion)
    func cancelUploadFile(srcPath: String, toFolder: String) -> Bool
    func deletePath(_ path: String, completion: @escaping deletePathCompletion)
    func createFolder(name: String, toFolder: String, completion: @escaping createFolderCompletion)
    func getUserInfo(completion: @escaping getUserInfoCompletion)
    
    // MARK: completion handler
    typealias getFilesCompletion = ([NXMyDriveFileItem]?, Error?) -> Void
    typealias downloadFileCompletion = (String, String, Error?) -> Void
    typealias rangeDownloadFileCompletion = (String, Data?, Error?) -> Void
    typealias fileProgressCompletion = (String, Double) -> Void
    typealias uploadFileCompletion = (String, String?, NXMyDriveFileItem?, Error?) -> Void
    typealias deletePathCompletion = (String, Error?) -> Void
    typealias createFolderCompletion = (NXMyDriveFileItem?, Error?) -> Void
    typealias getUserInfoCompletion = (Int64?, Int64?, Int64?, Error?) -> Void
    
}

class NXMyDriveRestProvider {
    
    init(withUserID userID: String, ticket: String) {
        MyDriveAPI.setting(withUserID: userID, ticket: ticket)
    }
    
    fileprivate var operationManager = NXRestOperationManager<NXMyDriveRestOperation>()
    
    fileprivate struct Constant {
        static let kPathId = "pathId"
        static let kPathDisplay = "pathDisplay"
        static let kName = "name"
        static let kFolder = "folder"
        static let kSize = "size"
        static let kLastModified = "lastModified"
        static let kQuery = "query"
        static let kStart = "start"
        static let kLength = "length"
        static let kParentPathId = "parentPathId"
        static let kSrcPathId = "srcPathId"
        static let kDestPathId = "destPathId"
        static let kUserId = "userId"
        static let kTicket = "ticket"
    }
}


// MARK: - Interface realize
extension NXMyDriveRestProvider: NXMyDriveRestProviderOperation {

    func getFiles(_ path: String, recursive: Bool, completion: @escaping NXMyDriveRestProviderOperation.getFilesCompletion) {

        let api = MyDriveAPI(type: .listFiles)
        
        let op = NXMyDriveRestOperation(withRestAPI: api, from: path)
        operationManager.add(element: op)
        
        let objectDic = [Constant.kPathId: path]
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            _ = self.operationManager.remove(element: op)
            
            let items: [NXMyDriveFileItem]? = {
                if error == nil, let response = response as? MyDriveResponse.ListFilesResponse {
                    return response.items
                }
                
                return nil
            }()
            
            completion(items, error)
        }
        
        api.sendRequest(withParameters: objectDic, completion: completion)
    }
    
    func cancelGetFiles(_ path: String) -> Bool {
        let op = NXMyDriveRestOperation(withRestAPI: MyDriveAPI(type: .listFiles), from: path)
        return operationManager.cancel(element: op)
    }
    
    func downloadFile(from path: String, to destPath: String, size: Int, progressCompletion: @escaping NXMyDriveRestProviderOperation.fileProgressCompletion, completion: @escaping NXMyDriveRestProviderOperation.downloadFileCompletion) {
        let parameters: [String: Any] = [Constant.kPathId: path, Constant.kStart: 0, Constant.kLength: size]
        
        let api = MyDriveAPI(type: .downloadFile)
        let toFolder: String? = {
            let range = destPath.range(of: "/", options: .backwards)
            if let notnilRange = range {
                return String(destPath[..<notnilRange.upperBound])
            }
            
            return nil
        }()
        
        let op = NXMyDriveRestOperation(withRestAPI: api, from: path, toFolder: toFolder)
        operationManager.add(element: op)
        
        let progress: (Double) -> Void = {
            progress in
            progressCompletion(path, progress)
        }
        let completion: (Any?, Error?) -> Void = {
            _, error in
            
            _ = self.operationManager.remove(element: op)
            
            DispatchQueue.main.async {
                completion(path, destPath, error)
            }

        }
        
        api.downloadFile(withParameters: parameters, destination: destPath, progress: progress, completion: completion)
    }
    
    func rangeDownloadFile(from path: String, start: Int, size: Int, progressCompletion: @escaping NXMyDriveRestProviderOperation.fileProgressCompletion, completion: @escaping NXMyDriveRestProviderOperation.rangeDownloadFileCompletion) {
        
        let parameters: [String: Any] = [Constant.kPathId: path, Constant.kStart: start, Constant.kLength: size]
        
        let api = MyDriveAPI(type: .rangeDownloadFile)
        let op = NXMyDriveRestOperation(withRestAPI: api, from: path, toFolder: nil)
        operationManager.add(element: op)
        
        let progress: (Double) -> Void = {
            progress in
            progressCompletion(path, progress)
        }
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            _ = self.operationManager.remove(element: op)
            let data: Data? = {
                if error == nil, let response = response as? MyDriveResponse.RangeDownloadFileResponse {
                    return response.resultData
                }
                return nil
            }()
            DispatchQueue.main.async {
                completion(path, data, error)
            }
            
        }
        
        api.sendRequest(withParameters: parameters, progress: progress, completion: completion)
    }

    func cancelDownload(servicePath path: String, toFolder folderPath: String?) -> Bool {
        let op = NXMyDriveRestOperation(withRestAPI: MyDriveAPI(type: .downloadFile), from: path, toFolder: folderPath)
        return operationManager.cancel(element: op)
    }
    
    func cancelRangeDownload(servicePath path: String) -> Bool {
        let op = NXMyDriveRestOperation(withRestAPI: MyDriveAPI(type: .rangeDownloadFile), from: path, toFolder: nil)
        return operationManager.cancel(element: op)
    }
    
    func uploadfile(filename: String, fromPath srcPath: String, toFolder folderPath: String, progressCompletion: @escaping NXMyDriveRestProviderOperation.fileProgressCompletion, completion: @escaping NXMyDriveRestProviderOperation.uploadFileCompletion) {
        
        let api = MyDriveAPI(type: .uploadFile)
        let op = NXMyDriveRestOperation(withRestAPI: api, from: srcPath, toFolder: folderPath)
        operationManager.add(element: op)
        
        let pathDic = [Constant.kParentPathId: folderPath, Constant.kName: filename]
        guard let data = try? Data.init(contentsOf: URL(fileURLWithPath: srcPath)) else {
            return
        }
        let parameter = ["fileData": data, "object": pathDic] as [String : Any]
        
        let progress: (Double) -> Void = {
            progress in
            progressCompletion(srcPath, progress)
        }
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            _ = self.operationManager.remove(element: op)
            
            var cachePath: String?
            var item: NXMyDriveFileItem?
            if error == nil, let response = response as? MyDriveResponse.UploadFileResponse {
                cachePath = response.item.path
                item = response.item
            }
            
            completion(srcPath, cachePath, item, error)
        }
        
        api.uploadFile(withParameters: parameter, progress: progress, completion: completion)
    }
    
    func cancelUploadFile(srcPath: String, toFolder: String) -> Bool {
        let op = NXMyDriveRestOperation(withRestAPI: MyDriveAPI(type: .uploadFile), from: srcPath, toFolder: toFolder)
        return operationManager.cancel(element: op)
    }
    
    func deletePath(_ path: String, completion: @escaping NXMyDriveRestProviderOperation.deletePathCompletion) {
        let parameter = [Constant.kPathId: path]
        let completion: (Any?, Error?) -> Void = {
            _, error in
            completion(path, error)
        }
        let api = MyDriveAPI(type: .deleteItem)
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func createFolder(name: String, toFolder: String, completion: @escaping NXMyDriveRestProviderOperation.createFolderCompletion) {
        let objectDic = [Constant.kParentPathId: toFolder, Constant.kName: name]
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            let item: NXMyDriveFileItem? = {
                if error == nil, let response = response as? MyDriveResponse.CreateFolderResponse {
                    return response.item
                }
                return nil
            }()
            
            completion(item, error)
        }
        let api = MyDriveAPI(type: .createFolder)
        api.sendRequest(withParameters: objectDic, completion: completion)
    }
    
    func getUserInfo(completion: @escaping NXMyDriveRestProviderOperation.getUserInfoCompletion) {
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            var totalQuota, usedQuota, vaultQuota : Int64?
            if error == nil, let responseObject = response as? MyDriveResponse.GetStorageUsedResponse {
                totalQuota = responseObject.quota
                usedQuota = responseObject.usage
                vaultQuota = responseObject.vaultUsage
            }
            completion(totalQuota, usedQuota, vaultQuota, error)
        }
        let api = MyDriveAPI(type: .getStorageUsed)
        api.sendRequest(withParameters: nil, completion: completion)
    }
}

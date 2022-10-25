//
//  NXRepositoryFileService.swift
//  skyDRM
//
//  Created by pchen on 13/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol NXRepositoryFileServiceOperation {
    func getFavFile(repoId: String, lastModified: String?, customData: Any?)
    func cancelFavFile(with repoId: String) -> Bool
    func markAsFavFile(files: [NXFileBase])
    func unmarkFavFile(files: [NXFileBase])
    
    func getAllFavFiles()
}

protocol NXRepositoryFileServiceOperationDelegate: NSObjectProtocol {
    func getFavFileFinish(repoId: String, favFile: NXRepoFavFileItem?, error: Error?, customData: Any?)
    func markAsFavFileFinish(files: [NXFileBase], error: Error?)
    func unmarkFavFileFinish(files: [NXFileBase], error: Error?)
    
    func getAllFavFilesFinish(files: [NXRepoFavFileItem]?, error: Error?)
}

// Optional
extension NXRepositoryFileServiceOperationDelegate {
    func getFavFileFinish(repoId: String, favFile: NXRepoFavFileItem?, error: Error?, customData: Any?) {}
    func markAsFavFileFinish(files: [NXFileBase], error: Error?) {}
    func unmarkFavFileFinish(files: [NXFileBase], error: Error?) {}
    
    func getAllFavFilesFinish(files: [NXRepoFavFileItem]?, error: Error?) {}
}

class NXRepositoryFileService {
    
    init(withUserID userId: String, ticket: String) {
        RepositoryFileAPI.setting(withUserID: userId, ticket: ticket)
    }
    
    weak var delegate: NXRepositoryFileServiceOperationDelegate?
    var manager = [String: RepositoryFileAPI]()
}

extension NXRepositoryFileService: NXRepositoryFileServiceOperation {
    
    struct Constant {
        static let kRepoId = "repoId"
        static let kFile = "files"
        static let kFileId = "pathId"
        static let kFilePath = "pathDisplay"
        static let kParentFileId = "parentFileId"
        static let kFileSize = "fileSize"
        static let kFileLastModified = "fileLastModified"
    }
    
    func getFavFile(repoId: String, lastModified: String?, customData: Any?) {
        var parameter: [String: Any] = [RequestParameter.url: [Constant.kRepoId: repoId]]
        if lastModified != nil {
            let filter = GetFavFilter(lastModified: lastModified!)
            parameter.updateValue(filter, forKey: RequestParameter.filter)
        }

        let completion: CallBack = {
            response, error in
            var result: NXRepoFavFileItem?
            if let response = response as? RepositoryFileResponse.GetFavFileResponse {
                result = response.repoItem
            }
            self.delegate?.getFavFileFinish(repoId: repoId, favFile: result, error: error, customData: customData)
        }
        let api = RepositoryFileAPI(type: .getFavFile)
        api.sendRequest(withParameters: parameter, completion: completion)
        
        manager[repoId] = api
    }
    
    func cancelFavFile(with repoId: String) -> Bool {
        guard let api = manager[repoId] else {
            return false
        }
        return api.cancel()
    }
    
    func markAsFavFile(files: [NXFileBase]) {
        // TODO: get repoId
        guard let repoId = files.first?.repoId else {
            return
        }
        let filesParam = files.map() {
            file -> [String : Any] in
            let minSecondsToSecond: Int64 = 1000
            let interval = Int64(file.lastModifiedDate.timeIntervalSince1970)
            let lastModifiedStr = String(interval * minSecondsToSecond)
            return [Constant.kFileId: file.fullServicePath,
                    Constant.kFilePath: file.fullPath,
                    Constant.kParentFileId: file.parent?.fullServicePath ?? "/",
                    Constant.kFileSize: file.size,
                    Constant.kFileLastModified: lastModifiedStr]
        }
        let parameter: [String: Any] = [RequestParameter.url: [Constant.kRepoId: repoId],
                                        RequestParameter.body: [Constant.kFile: filesParam]]
        
        let completion: CallBack = {
            _, error in
            let favFiles: [NXFileBase] = files.map() {
                if error == nil {
                    $0.isFavorite = true
                }
                return $0
            }
            self.delegate?.markAsFavFileFinish(files: favFiles, error: error)
        }
        let api = RepositoryFileAPI(type: .markFavFile)
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func unmarkFavFile(files: [NXFileBase]) {
        // TODO: get repoId
        guard let repoId = files.first?.repoId else {
            return
        }
        let filesParam = files.map() {
            file in
            return [Constant.kFileId: file.fullServicePath, Constant.kFilePath: file.fullPath]
        }
        let parameter: [String: Any] = [RequestParameter.url: [Constant.kRepoId: repoId],
                                        RequestParameter.body: [Constant.kFile: filesParam]]
        
        let completion: CallBack = {
            _, error in
            let unfavFiles: [NXFileBase] = files.map() {
                if error == nil {
                    $0.isFavorite = false
                }
                return $0
            }
            self.delegate?.unmarkFavFileFinish(files: unfavFiles, error: error)
        }
        let api = RepositoryFileAPI(type: .unmarkFavFile)
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func getAllFavFiles() {
        let completion: CallBack = {
            response, error in
            var repos: [NXRepoFavFileItem]?
            if let response = response as? RepositoryFileResponse.GetAllFavFileResponse {
                repos = response.repos
            }
            self.delegate?.getAllFavFilesFinish(files: repos, error: error)
        }
        let api = RepositoryFileAPI(type: .getAllFavFile)
        api.sendRequest(withParameters: nil, completion: completion)
    }
}

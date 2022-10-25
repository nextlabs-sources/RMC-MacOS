//
//  NXRepositoryService.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/22.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

@objc protocol NXRepositoryServiceDelegate: NSObjectProtocol {
    @objc optional func getRepositoriesFinished(repositories: Array<Any>?, error: Error?)
    @objc optional func addRepositoryFinished(repoId: String?, error: Error?)
    @objc optional func updateRepositoryFinished(error: Error?)
    @objc optional func removeRepositoryFinished(error: Error?)
}

class NXRepositoryService {
    init(userID: String, ticket: String) {
        RepositoryRestAPI.setting(withUserID: userID, ticket: ticket)
    }
    weak var delegate: NXRepositoryServiceDelegate?
    
    //MARK: public interface
    func getRepositories() {
        var repos: [NXRMCRepoItem] = []
        let api = RepositoryRestAPI(type: .getRepositories)
        api.sendRequest(withParameters: nil, completion: {response, error in
            if error == nil,
                let responseObject = response as? RepositoryRestResponse.GetRepositoriesResponse {
                for item in responseObject.repoItems {
                    if item.type == .kServiceSharepointOnline {
                        let tempItem = item.copy() as! NXRMCRepoItem
                        tempItem.accountId = item.accountName
                        tempItem.accountName = item.accountId
                        repos.append(tempItem)
                    }
                    else if item.type == .kServiceDropbox ||
                        item.type == .kServiceGoogleDrive ||
                        item.type == .kServiceOneDrive ||
                        item.type == .kServiceSkyDrmBox {
                        repos.append(item)
                    }
                }
            }
            guard let delegate = self.delegate,
                delegate.responds(to: #selector(NXRepositoryServiceDelegate.getRepositoriesFinished(repositories:error:))) else {
                    return
            }
            delegate.getRepositoriesFinished!(repositories: repos, error: error)
        })
    }
    func addRepository(repo: NXRMCRepoItem) {
        let tempRepo = repo.copy() as! NXRMCRepoItem
        if repo.type == .kServiceSharepointOnline {
            tempRepo.accountId = repo.accountName
            tempRepo.accountName = repo.accountId
        }
        var repoId: String?
        let api = RepositoryRestAPI(type: .addRepository)
        api.sendRequest(withParameters: tempRepo, completion: {response, error in
            if error == nil,
                let responseObject = response as? RepositoryRestResponse.AddRepositoryResponse {
                repoId = responseObject.repoId
            }
            guard let delegate = self.delegate,
                delegate.responds(to: #selector(NXRepositoryServiceDelegate.addRepositoryFinished(repoId:error:))) else {
                    return
            }
            delegate.addRepositoryFinished!(repoId: repoId, error: error)
        })
    }
    func updateRepository(repo: NXRMCRepoItem) {
        let tempRepo = repo.copy() as! NXRMCRepoItem
        if repo.type == .kServiceSharepointOnline {
            tempRepo.accountId = repo.accountName
            tempRepo.accountName = repo.accountId
        }
        let api = RepositoryRestAPI(type: .updateRepository)
        api.sendRequest(withParameters: tempRepo, completion: {response, error in
            guard let delegate = self.delegate,
                delegate.responds(to: #selector(NXRepositoryServiceDelegate.updateRepositoryFinished(error:))) else {
                    return
            }
            delegate.updateRepositoryFinished!(error: error)
        })
    }
    func removeRepository(repo: NXRMCRepoItem) {
        let api = RepositoryRestAPI(type: .removeRepository)
        api.sendRequest(withParameters: repo, completion: {response, error in
            guard let delegate = self.delegate,
                delegate.responds(to: #selector(NXRepositoryServiceDelegate.removeRepositoryFinished(error:))) else {
                    return
            }
            delegate.removeRepositoryFinished!(error: error)
        })
    }
}

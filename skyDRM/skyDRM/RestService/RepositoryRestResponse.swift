//
//  RepositoryRestResponse.swift
//  skyDRM
//
//  Created by pchen on 12/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class RepositoryRestResponse: RestResponse {
    
    override func responeObject(responseType: Int, response: HTTPURLResponse, representation: Any) -> Any? {
        guard let type = RepositoryRestAPI.RepositoryRestAPIType(rawValue: responseType) else {
            return nil
        }
        switch type {
        case .addRepository:
            return AddRepositoryResponse(response: response, representation: representation)
        case .getRepositories:
            return GetRepositoriesResponse(response: response, representation: representation)
        case .updateRepository:
            return UpdateRepositoryResponse(response: response, representation: representation)
        case .removeRepository:
            return RemoveRepositoryResponse(response: response, representation: representation)
        }
    }
    
    struct AddRepositoryResponse: ResponseObjectSerializable {
        let repoId: String
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let repoId = results["repoId"] as? String
            else { return nil }
            
            self.repoId = repoId
        }
    }
    struct GetRepositoriesResponse: ResponseObjectSerializable {
        var repoItems = [NXRMCRepoItem]()
        
        init?(response: HTTPURLResponse, representation: Any) {
            
            guard let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
            let items = results["repoItems"] as? Array<[String: Any]>
                else { return nil }
            
            for item in items {
                let repoItem = NXRMCRepoItem(dic: item)
                repoItems.append(repoItem)
            }
        }
    }
    struct UpdateRepositoryResponse: ResponseObjectSerializable {
        init?(response: HTTPURLResponse, representation: Any) {
            return
        }
    }
    struct RemoveRepositoryResponse: ResponseObjectSerializable {
        init?(response: HTTPURLResponse, representation: Any) {
            return
        }
    }
    
}

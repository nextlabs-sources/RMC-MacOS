//
//  RepositoryFileResponse.swift
//  skyDRM
//
//  Created by pchen on 13/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class RepositoryFileResponse: RestResponse {
    override func responeObject(responseType: Int, response: HTTPURLResponse, representation: Any) -> Any? {
        let type = RepositoryFileAPI.RepositoryFileAPIType(rawValue: responseType)!
        switch type {
        case .getFavFile:
            return GetFavFileResponse(response: response, representation: representation)
        case .markFavFile:
            return MarkFavFileResponse(response: response, representation: representation)
        case .unmarkFavFile:
            return UnmarkFavFileResponse(response: response, representation: representation)
            
        case .getAllFavFile:
            return GetAllFavFileResponse(response: response, representation: representation)
        }
    }
    
    struct GetFavFileResponse: ResponseObjectSerializable {
        var repoItem: NXRepoFavFileItem?
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any]
                else { return }
            
            repoItem = NXRepoFavFileItem(with: results)
        }
    }
    
    struct MarkFavFileResponse: ResponseObjectSerializable {
        init?(response: HTTPURLResponse, representation: Any) {
        }
    }
    
    struct UnmarkFavFileResponse: ResponseObjectSerializable {
        init?(response: HTTPURLResponse, representation: Any) {
        }
    }
    
    struct GetAllFavFileResponse: ResponseObjectSerializable {
        var repos: [NXRepoFavFileItem]?
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any],
                let repos = results["repos"] as? [[String: Any]]
                else { return }
            
            self.repos = repos.map() { NXRepoFavFileItem(with: $0) }
        }
    }
}

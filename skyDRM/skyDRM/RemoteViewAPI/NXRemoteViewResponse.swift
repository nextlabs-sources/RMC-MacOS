//
//  NXRemoteViewResponse.swift
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 4/27/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXRemoteViewResponse: RestResponse {
    override func responeObject(responseType: Int, response: HTTPURLResponse, representation: Any) -> Any? {
        guard let type = NXRemoteViewAPI.NXRemoteViewAPIType(rawValue: responseType) else {
            return nil
        }
        
        switch type {
        case .viewVDS:
            return NXRemoteViewResponse.viewVDSResponse(response: response, representation: representation)
        case .viewRepo:
            return NXRemoteViewResponse.viewRepoResponse(response: response, representation: representation)
        case .viewProject:
            return NXRemoteViewResponse.viewRepoResponse(response: response, representation: representation)
        }
    }
    
    struct viewVDSResponse: ResponseObjectSerializable {
        var viewVDSModel: NXRemoteViewModel
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any]
            else {
                return nil
            }
            
            viewVDSModel = NXRemoteViewModel(withDictionary: results)
        }
    }
    
    struct viewRepoResponse: ResponseObjectSerializable {
        var viewRepoModel: NXRemoteViewModel
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard
                let representation = representation as? [String: Any],
                let results = representation["results"] as? [String: Any]
                else {
                    return nil
            }
            
            viewRepoModel = NXRemoteViewModel(withDictionary: results)
        }
    }
    
    
}

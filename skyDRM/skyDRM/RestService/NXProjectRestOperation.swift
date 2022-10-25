//
//  NXProjectOperation.swift
//  skyDRM
//
//  Created by pchen on 16/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

struct NXProjectRestOperation {
    var api: RestAPI!
    
    var projectId: String?
    var path: String?
    
    // For File Download & Upload
    var from: String?
    var to: String?
    
    init(restAPI api: RestAPI!, projectId: String? = nil, path: String? = nil, from: String? = nil, to: String? = nil) {
        self.api = api
        self.projectId = projectId
        self.path = path
        self.from = from
        self.to = to
    }
}

extension NXProjectRestOperation: Equatable, Cancelable {
    public static func == (lhs: NXProjectRestOperation, rhs: NXProjectRestOperation) -> Bool {
        
        if lhs.api.apiType == rhs.api.apiType,
            lhs.projectId == rhs.projectId,
            lhs.path == rhs.path,
            lhs.from == rhs.from {
            
            if lhs.to == nil || rhs.to == nil || lhs.to == rhs.to {
                return true
            }
        }
        
        return false
    }
    
    func cancel() -> Bool {
        return api.cancel()
    }
    
}

//
//  NXBaseRestOperation.swift
//  skyDRM
//
//  Created by pchen on 27/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXBaseRestOperation {
    
    var api: RestAPI
    
    var from: String?
    var toFolder: String?
    
    init(withRestAPI api: RestAPI, from: String? = nil, toFolder: String? = nil) {
        self.api = api
        self.from = from
        
        if let toFolder = toFolder {
            self.toFolder = URL(fileURLWithPath: toFolder, isDirectory: true).path
        }
        
    }
}

extension NXBaseRestOperation: Cancelable {
    func cancel() -> Bool {
        return api.cancel()
    }
}

extension NXBaseRestOperation: Equatable {
    public static func ==(lhs: NXBaseRestOperation, rhs: NXBaseRestOperation) -> Bool {
        if lhs.api.apiType == rhs.api.apiType,
            lhs.from == rhs.from {
            
            // because 'to' path may be a temp position
            if lhs.toFolder == nil || rhs.toFolder == nil || lhs.toFolder == rhs.toFolder {
                return true
            }
        }
        
        return false
    }
}

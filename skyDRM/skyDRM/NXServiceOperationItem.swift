//
//  NXServiceOperationItem.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 25/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

enum NXSericeRequestType {
    case getlist
}

class NXServiceOperationItem: NXBaseOperationItem {
    // key
    var file: NXFileBase
    var type: NXSericeRequestType
    // value
    var service: NXServiceOperation?
    
    init(file: NXFileBase, type: NXSericeRequestType, service: NXServiceOperation?) {
        self.file = file
        self.type = type
        self.service = service
    }
    
    override func cancel() -> Bool {
        guard let service = service else {
            return false
        }
        
        if type == .getlist {
            return service.cancelGetFiles(folder: file)
        }
        
        return false
    }
    
    override func equalTo(item: NXBaseOperationItem) -> Bool {
        guard let item = item as? NXServiceOperationItem else {
            return false
        }
        
        if file == item.file,
            type == item.type {
            return true
        } else {
            return false
        }
        
    }
}


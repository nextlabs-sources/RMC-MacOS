//
//  NXFavOperationItem.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 26/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXFavOperationItem: NXBaseOperationItem {
    // key
    var repoId: String
    // value
    var service: NXRepositoryFileService?
    
    init(repoId: String, service: NXRepositoryFileService?) {
        self.repoId = repoId
        self.service = service
    }
    
    override func cancel() -> Bool {
        guard let service = service else {
            return false
        }
        
        return service.cancelFavFile(with: repoId)
    }
    
    override func equalTo(item: NXBaseOperationItem) -> Bool {
        guard let item = item as? NXFavOperationItem else {
            return false
        }
        
        if repoId == item.repoId {
            return true
        }
        
        return false
    }
}

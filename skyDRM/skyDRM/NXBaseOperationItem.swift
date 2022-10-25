//
//  NXBaseOperationItem.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 26/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXBaseOperationItem: Equatable, Cancelable {
    func cancel() -> Bool {
        return false
    }
    
    func equalTo(item: NXBaseOperationItem) -> Bool {
        return false
    }
}

func ==(lhs: NXBaseOperationItem, rhs: NXBaseOperationItem) -> Bool {
    return lhs.equalTo(item: rhs)
}

//
//  RestAPIManager.swift
//  skyDRM
//
//  Created by pchen on 15/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol Cancelable {
    func cancel() -> Bool
}

protocol RestOperationManagerAction {
    associatedtype T
    func add(element: T)
    func removeAll()
    func remove(element: T) -> Bool
    func cancelAll() -> Bool
    func cancel(element: T) -> Bool
    
    func get(element: T) -> T?
    func isEmpty() -> Bool
}

extension NXRestOperationManager: RestOperationManagerAction {
    func add(element: T) {
        operationArray.append(element)
        
    }
    
    func removeAll() {
        operationArray.removeAll()
        
    }
    
    func remove(element: T) -> Bool {
        for (index, op) in self.operationArray.enumerated() {
            if op == element {
                operationArray.remove(at: index)
                return true
            }
        }
        
        return false
    }
    
    func cancelAll() -> Bool {
        
        var returnValue = true
        
        for op in operationArray {
            if !cancel(element: op) {
                returnValue = false
            }
        }
        
        return returnValue
    }
    
    func cancel(element: T) -> Bool {
        for (_, op) in operationArray.enumerated() {
            if op == element {
                if op.cancel() {
                    return true
                } else {
                    return false
                }
            }
        }
        
        return false
    }
    
    func get(element: T) -> T? {
        for op in operationArray {
            if op == element {
                return op
            }
        }
        
        return nil
    }
    
    func isEmpty() -> Bool {
        return operationArray.isEmpty
    }
}

class NXRestOperationManager<T: Equatable & Cancelable> {
    
    var operationArray = [T]()
    
    
}

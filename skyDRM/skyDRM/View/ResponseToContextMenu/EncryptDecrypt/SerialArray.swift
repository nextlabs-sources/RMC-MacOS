//
//  SerialData.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 26/04/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol ArrayOperation {
    associatedtype T
    func getFirst() -> T?
    func removeFirst()
    func append(element: T)
    func isEmpty() -> Bool
    func removeAll()
}

extension SerialArray: ArrayOperation {
    func append(element: T) {
        serialQueue.async {
            self.array.append(element)
        }
    }
    
    func removeFirst() {
        serialQueue.async {
            self.array.remove(at: 0)
        }
    }
    
    func getFirst() -> T? {
        var first: T?
        serialQueue.sync {
            first = self.array.first
        }
        return first
    }
    
    func isEmpty() -> Bool {
        var isEmpty: Bool = false
        serialQueue.sync {
            isEmpty = self.array.isEmpty
        }
        return isEmpty
    }
    
    func removeAll() {
        serialQueue.async {
            self.array.removeAll()
        }
    }
}

class SerialArray<T>: NSObject {
    
    var array = [T]()
    var serialQueue: DispatchQueue
    init(with label: String) {
        serialQueue = DispatchQueue(label: label)
    }
}

//
//  PendingServices.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 20/04/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

enum PendingTaskType {
    case openFile
    case encryptAndDecrypt
    case shareFile
    case checkPermission
    case protectFile
    case addFileToProject
    
}

class PendingTask: NSObject {
    
    static let sharedInstance = PendingTask()
    
    fileprivate var tasks = [(taskType: PendingTaskType, filePaths: [String])]()
    
    func removeAll() -> Bool {
        tasks.removeAll()
        return true
    }
    
    func getFilePaths(with taskType: PendingTaskType) -> [[String]] {
        let filterTask = tasks.filter() { $0.taskType == taskType }
        return filterTask.map() { $0.filePaths }
    }
    
    func addTask(with taskType: PendingTaskType, filePaths: [String]) -> Bool {
        tasks.append((taskType, filePaths))
        return true
    }
}

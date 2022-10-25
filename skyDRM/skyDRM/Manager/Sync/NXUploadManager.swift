//
//  NXUploadManager.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 11/06/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

protocol NXUploadManagerDelegate: class {
    func waitUploading(file:NXSyncFile)
    func startUploading(file: NXSyncFile)
    func cancelled(file: NXSyncFile)
    func uploadFinish(file: NXSyncFile, newFile: NXFileBase?, error: Error?)
    
}

protocol NXUploadManangerOperation {
    func upload(file: NXSyncFile)
    func cancel(file: NXSyncFile)
    func cancelAll()
    
}

class NXUploadManager {
    struct Constant {
        static let maxCocurrentUploadCount = 3
    }
    
    init() {
        self.queue = {
            let operationQueue = OperationQueue()
            
            operationQueue.maxConcurrentOperationCount = Constant.maxCocurrentUploadCount
            operationQueue.qualityOfService = .utility
            return operationQueue
        }()
    }
    
    fileprivate let queue: OperationQueue
    
    let serialQueue = DispatchQueue.init(label: "com.nxrmc.skydrm.NXUploadManager")
    var operations = [String: NXUploadOperation]()
    weak var delegate: NXUploadManagerDelegate?
    
    var stopUploadAllGroup: DispatchGroup?
}

// MARK: - Public methods.

extension NXUploadManager: NXUploadManangerOperation {
    func upload(file: NXSyncFile) {
        debugPrint("\(Date()): \(String(describing: self))-upload")
        
        let key = getKey(file: file)
        file.syncStatus?.status = .syncing
        let operation = NXUploadOperation(file: file, delegate: self)
        addOperation(key: key, value: operation)
        NXDebug.print(instance: self, functionName: "upload", addition: file.file.name)
        queue.addOperation(operation)
    }
    
    func cancel(file: NXSyncFile) {
        debugPrint("\(Date()): \(String(describing: self))-cancel")
        file.syncStatus?.status = .pending
        let key = getKey(file: file)
        let operation = getOperation(key: key)
        operation?.cancel()
    }
    
    func cancelAll() {
        
        let group = DispatchGroup()
        self.stopUploadAllGroup = group
        for _ in 0..<getOperationCount() {
            group.enter()
        }
        print("group count: \(operations.count)")
        group.notify(queue: DispatchQueue.main) {
            self.stopUploadAllGroup = nil
            NotificationCenter.post(notification: .stopUploadAllFinish)
            
        }
        
        debugPrint("\(Date()): \(String(describing: self))-cancelAll")
        queue.cancelAllOperations()
    }
    
}

extension NXUploadManager: NXUploadOperationDelegate {
    func execute(op: NXUploadOperation) {
        debugPrint("\(Date()): \(String(describing: self))-execute")
        delegate?.startUploading(file: op.file)
    }
    
    func cancel(op: NXUploadOperation) {
        debugPrint("\(Date()): \(String(describing: self))-cancel finish")
        op.file.syncStatus?.status = .failed
        removeOperation(key: getKey(file: op.file))
        delegate?.cancelled(file: op.file)
        
        print("\(op) \(op.isCancelled) group count: cancel: -1")
        self.stopUploadAllGroup?.leave()
        
    }
    
    func finish(op: NXUploadOperation, newFile: NXFileBase?, error: Error?) {
        debugPrint("\(Date()): \(String(describing: self))-finish")
        op.file.syncStatus?.status = .completed
        removeOperation(key: getKey(file: op.file))
        delegate?.uploadFinish(file: op.file, newFile: newFile, error: error)
        
        print("\(op) \(op.isCancelled) group count: finish: -1")
        self.stopUploadAllGroup?.leave()
    }
}

extension NXUploadManager {
    func getOperation(key: String) -> NXUploadOperation? {
        return serialQueue.sync { self.operations[key] }
    }
    
    func addOperation(key: String, value: NXUploadOperation) {
        serialQueue.async {
            self.operations[key] = value
        }
    }
    
    func removeOperation(key: String) {
        serialQueue.async {
            _ = self.operations.removeValue(forKey: key)
        }
    }
    
    func getOperationCount() -> Int {
        var count = 0
        serialQueue.sync {
            count = self.operations.count
        }
        return count
    }
}

extension NXUploadManager {
    fileprivate func getKey(file: NXSyncFile) -> String {
        return file.file.getNXLID()!
    }
    
}

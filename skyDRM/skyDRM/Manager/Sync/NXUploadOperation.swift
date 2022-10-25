//
//  NXUploadOperation.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 2018/8/21.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa
import SDML

enum NXOperationStatus: String {
    case initiallize
    case isExecuting
    case isFinished
}

protocol NXUploadOperationDelegate: class {
    func execute(op: NXUploadOperation)
    func cancel(op: NXUploadOperation)
    func finish(op: NXUploadOperation, newFile: NXFileBase?, error: Error?)
    
}

class NXUploadOperation: Operation {
    
    init(file: NXSyncFile, delegate: NXUploadOperationDelegate) {
        
        self.file = file
        self.delegate = delegate
        super.init()
    }
    
    let file: NXSyncFile
    weak var delegate: NXUploadOperationDelegate?
    
    let concurrentQueue = DispatchQueue(label: "com.nxrmc.NXUploadOperation", qos: .default, attributes: .concurrent)
    var _status = NXOperationStatus.initiallize
    var status: NXOperationStatus {
        get {
            return concurrentQueue.sync {
                return _status
            }
        }
        set {
            let workItem = DispatchWorkItem(flags: .barrier) {
                self._status = newValue
            }
            concurrentQueue.sync(execute: workItem)
        }
    }
    
    var uploadID: String?
    
    let lock = NSLock()
    
    override func start() {
        debugPrint("\(Date()): \(String(describing: self))-\(Thread.current)-start")
        
        if self.isCancelled {
            markFinished()
            delegate?.cancel(op: self)
            return
        }

        self.upload()
    }
    
    override func cancel() {
        lock.lock()
        defer { lock.unlock() }
        
        super.cancel()
        
        if let uploadID = uploadID {
            
            if let _ = file.file as? NXWorkspaceLocalFile {
                _ = NXClient.getCurrentClient().getWorkspace()?.cancel(id: uploadID)
                return
            }
            
            _ = NXClient.getCurrentClient().cancel(id: uploadID)
        }
        
    }
    
    override var isExecuting: Bool {
        return (status == .isExecuting) ? true : false
    }
    
    override var isFinished: Bool {
        return (status == .isFinished) ? true : false
    }
}

extension NXUploadOperation {
    func upload() {
        markExecuting()
        debugPrint("\(Date()): \(String(describing: self))-\(Thread.current)-execute")
        delegate?.execute(op: self)
        debugPrint("\(Date()): \(String(describing: self))-\(Thread.current)-execute2")
        
        lock.lock()
        defer { lock.unlock() }
        
        if self.isCancelled {
            markFinished()
            delegate?.cancel(op: self)
            return
        }
        
        if let workspaceFile = file.file as? NXWorkspaceLocalFile {
            let isLeaveCopy = NXClientUser.shared.setting.getIsUploadLeaveCopy()
            
            var parent: NXWorkspaceFile?
            if let parentFile = workspaceFile.parent as? NXWorkspaceFile {
                parent = parentFile
            }
            
            uploadID = NXClient.getCurrentClient().getWorkspace()?.addFile(file: file.file, parent: parent, isLeaveCopy: isLeaveCopy, progress: nil, completion: { (file, error) in
                if let sdmlError = error as? SDMLError,
                    case SDMLError.commonFailed(reason: .cancel) = sdmlError {
                    self.markFinished()
                    self.delegate?.cancel(op: self)
                    return
                }
                
                self.markFinished()
                
                self.delegate?.finish(op: self, newFile: file, error: error)
            })
            
            return
        }
        
        uploadID = NXClient.getCurrentClient().upload(file: file.file, project: nil, progress: {value in debugPrint("\(String(describing: self))-\(value)") }) { (file, error) in
            
            if let sdmlError = error as? SDMLError,
                case SDMLError.commonFailed(reason: .cancel) = sdmlError {
                self.markFinished()
                self.delegate?.cancel(op: self)
                return
            }
            
            self.markFinished()
            
            self.delegate?.finish(op: self, newFile: file, error: error)
        }
        
    }
    
    func markExecuting() {
        self.willChangeValue(forKey: NXOperationStatus.isExecuting.rawValue)
        self.status = .isExecuting
        self.didChangeValue(forKey: NXOperationStatus.isExecuting.rawValue)
    }
    
    func markFinished() {
        self.willChangeValue(forKey: NXOperationStatus.isExecuting.rawValue)
        self.willChangeValue(forKey: NXOperationStatus.isFinished.rawValue)
        self.status = .isFinished
        self.didChangeValue(forKey: NXOperationStatus.isExecuting.rawValue)
        self.didChangeValue(forKey: NXOperationStatus.isFinished.rawValue)
    }
}

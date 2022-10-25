//
//  NXDownloadManager.swift
//  
//
//  Created by William (Weiyan) Zhao on 2018/12/10.
//

import Foundation
protocol NXDownloadManagerDelegate:class {
  func  downloadFile(file:NXSyncFile)

}

protocol NXDownloadManagerOperation {
    func download(file:NXSyncFile)
}

class NXDownloadManager {
    struct Constant {
        static let maxConstantDownloadCount = 3
    }
    init() {
       self.queue = {
        let operationQueue = OperationQueue()
            operationQueue.maxConcurrentOperationCount = Constant.maxConstantDownloadCount
            operationQueue.qualityOfService = .utility
            return operationQueue
        }()
    }
    fileprivate let queue:OperationQueue
    let serialQueue = DispatchQueue.init(label: "com.nxrmc.skydrm.NXDownloadManager")
    var operation = [String:NXDownloadOperation]()
    weak var delegate:NXDownloadManagerDelegate?
    
}
extension NXDownloadManager:NXDownloadManagerOperation {
    func download(file:NXSyncFile) {
          debugPrint("\(Date()): \(String(describing: self))-download")
        _ = getKey(file:file)
    }
    
    
    
}
extension NXDownloadManager {
    fileprivate func getKey(file:NXSyncFile) -> String {
        return file.file.getNXLID()!
    }
}

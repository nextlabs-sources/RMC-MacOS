//
//  NXDownloadOperation.swift
//  skyDRM
//
//  Created by William (Weiyan) Zhao on 2018/12/10.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa

class NXDownloadOperation:Operation {
    init(file:NXSyncFile) {
        self.file = file
    }
    let file:NXSyncFile
    
    //Use GCD
    var downloadId:String?
    override func start() {
        debugPrint("\(Date()): \(String(describing: self))-\(Thread.current)-cancel")
        
    }    
}

extension NXDownloadManager {
    func download() {
        
    }
}

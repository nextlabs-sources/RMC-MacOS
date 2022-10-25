//
//  NXNormalFileMenuView.swift
//  skyDRM
//
//  Created by Kevin on 2017/2/10.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXNormalFileMenuView: NSView {
    weak var delegate: NXFileOperationDelegate? = nil
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    @IBAction func downloadFile(_ sender: Any) {
        delegate?.nxFileOperation(type: .downloadFile)
    }
    
    @IBAction func protectFile(_ sender: Any) {
        delegate?.nxFileOperation(type: .protectFile)
    }
    
    @IBAction func shareFile(_ sender: Any) {
        delegate?.nxFileOperation(type: .shareFile)
    }
    
    @IBAction func viewProperty(_ sender: Any) {
        delegate?.nxFileOperation(type: .viewProperty)
    }
    
    @IBAction func deleteFile(_ sender: Any) {
        delegate?.nxFileOperation(type: .deleteFile)
    }
    
}

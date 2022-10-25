//
//  NXContextMenu.swift
//  skyDRM
//
//  Created by bill.zhang on 2/28/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXContextMenu: NSMenu {
    let operationTitles = [NXFileOperation.downloadFile:"Download",
                           NXFileOperation.protectFile : "Protect",
                           NXFileOperation.shareFile :"Share",
                           NXFileOperation.viewProperty : "View File Info",
                           NXFileOperation.deleteFile : "Delete",
                           NXFileOperation.logProperty : "View Activity",
                           NXFileOperation.markFavorite : "Mark as Favorite"
                            ]
    let operationImages = [NXFileOperation.downloadFile : NSImage(named: "downloadinmenu"),
                           NXFileOperation.protectFile : NSImage(named:  "protectinmenu"),
                           NXFileOperation.shareFile : NSImage(named:  "shareinmenu"),
                           NXFileOperation.viewProperty : NSImage(named: "fileinfomenu"),
                           NXFileOperation.deleteFile: NSImage(named: "deleteinmenu"),
                           NXFileOperation.logProperty: NSImage(named:  "logmenu")]
    weak var operationDelegate : NXFileOperationDelegate?
    private var operations : [NXFileOperation]?
    private var onOffOperations :[[NXFileOperation : Bool]]?
    
    init(operations:[NXFileOperation], onOffOperation:[[NXFileOperation : Bool]]) {
        super.init(title: "")
        self.operations = operations
        self.onOffOperations = onOffOperation
        self.commonInit()
    }
    
    required init(coder decoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public func menuItemClicked(sender:NSMenuItem){
        operationDelegate?.nxFileOperation(type: NXFileOperation(rawValue: sender.tag)!)
    }
    
    private func commonInit(){
        //step 1
        for operation : NXFileOperation in operations! {
            let item = NSMenuItem(title: operationTitles[operation]!, action: #selector(NXContextMenu.menuItemClicked), keyEquivalent: "")
            item.tag = operation.rawValue
            item.target = self
            self.addItem(item)
        }
        
        //step 2
        if (onOffOperations != nil) {
            self.addItem(NSMenuItem.separator())
            for operation in onOffOperations! {
                for key in operation.keys {
                    let item = NSMenuItem(title: operationTitles[key]!, action: #selector(NXContextMenu.menuItemClicked), keyEquivalent: "")
                    item.tag = key.rawValue
                    if operation[key]! {
                        item.state = NSControl.StateValue.on
                    } else {
                        item.state = NSControl.StateValue.off
                    }
                    
                    item.target = self
                    
                    self .addItem(item)
                }
            }
        }
    }
}

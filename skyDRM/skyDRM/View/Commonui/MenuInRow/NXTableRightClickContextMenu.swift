//
//  NXTableRightClickContextMenu.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 13/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXTableRightClickContextMenu: NSMenu {
    private let operationTitles: [NXFileOperation: String] = [.openFile: "Open",
                           .downloadFile:"Download",
                           .protectFile : "Protect",
                           .shareFile :"Share",
                           .viewProperty : "View File Info",
                           .deleteFile : "Delete",
                           .logProperty : "View Activity",
                           .viewDetails: "Details",
                           .viewManage: "Manage",
                           .markFavorite : "Mark as Favorite"]
    weak var operationDelegate: NXFileOperationDelegate?
    
    private var defaultOperations = [NXFileOperation]()
    private var candidateOperations = [NXFileOperation]()
    private var favOffOperations = [[NXFileOperation : Bool]]()
    
    weak var fileItem: NXFileBase? {
        didSet {
            self.commonInit()
        }
    }

    private func commonInit() {
        guard let fileItem = fileItem else {
            return
        }
        
        if fileItem is NXFolder  {
            if NXCommonUtils.is3rdRepo(node: fileItem){
                defaultOperations = [.openFile]
            }else{
                defaultOperations = [.openFile, .deleteFile]
            }
            candidateOperations = []
        } else if fileItem is NXProjectFolder {
            if NXCommonUtils.is3rdRepo(node: fileItem) || !NXSpecificProjectData.shared.getProjectInfo().ownedByMe {
                defaultOperations = [.openFile]
            }else{
                defaultOperations = [.openFile, .deleteFile]
            }
            candidateOperations = []
        }
        else if let file = fileItem as? NXNXLFile {
            
            // delete > revoke > protect > normal
            if file.isDeleted == true  {
                defaultOperations = [.viewDetails, .logProperty]
                candidateOperations = [.viewProperty]
            } else if file.isRevoked == true {
                defaultOperations = [.openFile, .viewDetails, .logProperty]
                candidateOperations = [.viewProperty, .downloadFile, .deleteFile]
            } else if file.isShared == false { // protect files
                defaultOperations = [.openFile, .shareFile, .logProperty]
                candidateOperations = [.viewProperty, .downloadFile, .deleteFile]
            } else {
                defaultOperations = [.openFile, .viewManage, .logProperty]
                candidateOperations = [.viewProperty, .downloadFile, .deleteFile]
            }
            
        } else if let file = fileItem as? NXSharedWithMeFile {
            
            if let rights = file.rights {
                var operations = [NXFileOperation]()
                operations.append(.openFile)
                operations.append(.viewProperty)
                if rights.contains(.share) || file.getIsOwner() {
                    operations.append(.shareFile)
                }
                if rights.contains(.saveAs) || file.getIsOwner() {
                    operations.append(.downloadFile)
                }
                
                defaultOperations = Array(operations.prefix(3))
                if operations.count > 3 {
                    candidateOperations = Array(operations.suffix(from: 3))
                } else {
                    candidateOperations = []
                }
            }
            
        } else if let file = fileItem as? NXProjectFile {
            if let ownerByMe = file.ownerByMe,
                ownerByMe == true {
                defaultOperations = [.openFile, .viewProperty, .logProperty]
                candidateOperations = [.downloadFile, .deleteFile]
            }else{
                defaultOperations = [.openFile, .viewProperty, .downloadFile]
            }
        } else if fileItem is NXFile {
            defaultOperations = [.openFile, .shareFile, .protectFile]
            if NXCommonUtils.is3rdRepo(node: fileItem){
                if NXCommonUtils.isNXLFile(path: (fileItem.localPath != "") ? fileItem.localPath : fileItem.name){
                    candidateOperations = [.viewProperty]
                }else{
                    candidateOperations = []
                }
                
            }else{
                candidateOperations = [.viewProperty, .downloadFile, .deleteFile]
                if NXCommonUtils.isNXLFile(path: (fileItem.localPath != "") ? fileItem.localPath : fileItem.name) {
                    candidateOperations.append(NXFileOperation.logProperty)
                }
            }
        }
        
        ////////////////////////////////////////////////////////////////////////////////
        // fav operation
        favOffOperations.removeAll()
        if !(fileItem is NXFolder || fileItem is NXProjectFolder) {
            if fileItem.boundService?.serviceType == ServiceType.kServiceSkyDrmBox.rawValue {
                if fileItem.isFavorite {
                    favOffOperations.append([.markFavorite : true])
                } else {
                    favOffOperations.append([.markFavorite : false])
                }
            } else if let file = fileItem as? NXNXLFile,
                file.isDeleted == false {
                if fileItem.isFavorite {
                    favOffOperations.append([.markFavorite : true])
                } else {
                    favOffOperations.append([.markFavorite : false])
                }
            }
        }
        initMenuItems()
    }
    private func initMenuItems(){
        self.removeAllItems()
        for operation in defaultOperations {
            let item = NSMenuItem(title: operationTitles[operation]!, action: #selector(NXTableRightClickContextMenu.menuItemClicked), keyEquivalent: "")
            item.tag = operation.rawValue
            item.target = self
            self.addItem(item)
        }
        if !candidateOperations.isEmpty {
            self.addItem(NSMenuItem.separator())
        }
        
        for operation in candidateOperations {
            let item = NSMenuItem(title: operationTitles[operation]!, action: #selector(NXTableRightClickContextMenu.menuItemClicked), keyEquivalent: "")
            item.tag = operation.rawValue
            item.target = self
            self.addItem(item)
        }
        
        if !favOffOperations.isEmpty {
            self.addItem(NSMenuItem.separator())
        }
        for operation in favOffOperations {
            for key in operation.keys {
                let item = NSMenuItem(title: operationTitles[key]!, action: #selector(NXTableRightClickContextMenu.menuItemClicked), keyEquivalent: "")
                item.tag = key.rawValue
                if operation[key]! {
                    item.state = NSControl.StateValue.on
                } else {
                    item.state = NSControl.StateValue.on
                }
                item.target = self
                self.addItem(item)
            }
        }

    }
    @objc public func menuItemClicked(sender:NSMenuItem){
        operationDelegate?.nxFileOperation(type: NXFileOperation(rawValue: sender.tag)!)
    }
}

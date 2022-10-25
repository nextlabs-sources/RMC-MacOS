//
//  NXLocalListItemContextMenu.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 23/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa
import SDML

enum NXLocalListItemContextMenuOperation: Int, CustomStringConvertible {
    case empty
    case share
    case viewFile
    case viewFileInfo
    case remove
    case openWeb
    case stopUpload
    case download
    case online
    case addFileToProject
    
    var description: String {
        switch self {
        case .share:
            return "FILE_OPERATION_SHARE".localized
        case .viewFile:
            return "FILE_OPERATION_VIEW".localized
        case .viewFileInfo:
            return "FILE_OPERATION_VIEWFILEINFO".localized
        case .remove:
            return "FILE_OPERATION_REMOVE_FILE".localized
        case .openWeb:
            return "FILE_OPERATION_WEB".localized
        case .stopUpload:
            return "FILE_OPERATION_STOPUPLOAD".localized
        case .download:
            return "FILE_OPERATION_MAKEAVAILABLE_OFFLINE".localized
        case .online :
            return "FILE_OPERATION_MAKEUNAVAILABLE_OFFLINE".localized
        case .addFileToProject:
            return "FILE_OPERATION_ADD_FILE".localized
        default:
            return ""
        }
    }
}

protocol NXLocalListItemContextMenuOperationDelegate: class {
    func menuItemClicked(type: NXLocalListItemContextMenuOperation, value: Any?)
}

class NXLocalListItemContextMenu: NSMenu {

    var file: NXSyncFile? {
        didSet {
            changeMenu()
        }
    }
    
    weak var operationDelegate: NXLocalListItemContextMenuOperationDelegate?
    
    private func changeMenu() {
        // Local file without upload.
        let defaultOperation: [NXLocalListItemContextMenuOperation] = [.share, .empty, .viewFile, .viewFileInfo, .empty, .remove, .empty, .openWeb]
        var operations: [NXLocalListItemContextMenuOperation] = defaultOperation
        if let type = file?.syncStatus?.type {
            switch type {
            case .download:
                if let status = file?.syncStatus?.status {
                    if let _ =  file?.file as? NXProjectFileModel {
                        switch status {
                        case .syncing:
                            operations = [.viewFileInfo, .empty, .empty,.openWeb]
                        case .pending, .failed:
                            operations = [.download,.addFileToProject,.viewFile, .viewFileInfo,.empty,.openWeb]
                        case.completed:
                           operations = [.online,.addFileToProject,.viewFile, .viewFileInfo,.empty,.openWeb]
                        case .waiting:
                            break
                        }
                    } else {
                        switch status {
                        case .syncing:
                            operations = [.viewFileInfo, .empty, .empty,.openWeb]
                        case .pending, .failed:
                            operations = [.download, .viewFile, .viewFileInfo, .empty, .openWeb]
                        case.completed:
                            operations = [.online,.viewFile,.viewFileInfo, .empty, .openWeb]
                        case .waiting:
                            break
                        }
                    }
                }
            case .upload:
            if let status = file?.syncStatus?.status {
                switch status {
                case .syncing:
                    operations = [.viewFileInfo, .empty, .openWeb]
                default:
                    break
                    }
                }
            }
        }
        
        if let outboxFile = file?.file.sdmlBaseFile as? SDMLOutBoxFile,
        outboxFile.getOutBoxFileType() == .projectFile || outboxFile.getOutBoxFileType() == .workspace {
            operations = [.viewFile, .viewFileInfo, .empty, .remove, .empty, .openWeb]
        }
        
        if file!.file.fileStatus.contains(.opened) {
            operations = [.viewFile, .openWeb]
        } else if file!.file.fileStatus.contains(.downloading) {
            operations = [.openWeb]
        } else if file!.file.fileStatus.contains(.uploading) {
            operations = [.openWeb]
        }
        
        settingMenu(with: operations)
    }
    
    private func settingMenu(with operations: [NXLocalListItemContextMenuOperation]) {
        autoenablesItems = false
        for operation in operations {
            let item: NSMenuItem
            switch operation {
            case .empty:
                item = NSMenuItem.separator()
            case .share:
                item = NSMenuItem(title: operation.description, action: #selector(NXLocalListItemContextMenu.menuItemClicked), keyEquivalent: "")
                item.tag = operation.rawValue
                item.target = self
                item.image = NSImage(named: "Share-ContextMenuIcon")
            case .addFileToProject:
                item = NSMenuItem(title: operation.description, action: #selector(NXLocalListItemContextMenu.menuItemClicked), keyEquivalent: "")
                item.tag = operation.rawValue
                item.target = self
                item.image = NSImage(named: "Addfile-ViewFile-ContextMenuIcon")
                
            case .viewFile:
                item = NSMenuItem(title: operation.description, action: #selector(NXLocalListItemContextMenu.menuItemClicked), keyEquivalent: "")
                item.tag = operation.rawValue
                item.target = self
                item.image = NSImage(named:  "ViewFile-ContextMenuIcon")
                
            case .viewFileInfo:
                item = NSMenuItem(title: operation.description, action: #selector(NXLocalListItemContextMenu.menuItemClicked), keyEquivalent: "")
                item.tag = operation.rawValue
                item.target = self
                item.image = NSImage(named: "ViewFileInfo-ContextMenuIcon")
                
            case .remove:
                item = NSMenuItem(title: operation.description, action: #selector(NXLocalListItemContextMenu.menuItemClicked), keyEquivalent: "")
                item.tag = operation.rawValue
                item.target = self
                item.image = NSImage(named: "Remove-ContextMenuIcon")
                
            case .openWeb:
                item = NSMenuItem(title: operation.description, action: #selector(NXLocalListItemContextMenu.menuItemClicked), keyEquivalent: "")
                item.tag = operation.rawValue
                item.target = self
                item.image = NSImage(named: "OpenSkyDRMCom-ContextMenuIcon")
                
            case .stopUpload:
                item = NSMenuItem(title: operation.description, action: #selector(NXLocalListItemContextMenu.menuItemClicked), keyEquivalent: "")
                item.tag = operation.rawValue
                item.target = self
                item.image = NSImage(named: "StopUpload-ToolBarIcon")
                
            case .download:
                item = NSMenuItem(title: operation.description, action: #selector(NXLocalListItemContextMenu.menuItemClicked), keyEquivalent: "")
                item.tag = operation.rawValue
                item.target = self
                item.image = NSImage(named: "Mark-availableoffline")
            case .online:
                item = NSMenuItem(title: operation.description, action: #selector(NXLocalListItemContextMenu.menuItemClicked), keyEquivalent: "")
                item.tag = operation.rawValue
                item.target = self
                item.image = NSImage(named: "Mark-availableoffline")

            }
            addItem(item)
        }
    }
    
   func validateMenuItem(_ menuItem: NSMenuItem) -> Bool {
        return true
    }
    
    @objc func menuItemClicked(sender: NSMenuItem) {
        let operation = NXLocalListItemContextMenuOperation(rawValue: sender.tag)!
        operationDelegate?.menuItemClicked(type: operation, value: self.file)
    }
}

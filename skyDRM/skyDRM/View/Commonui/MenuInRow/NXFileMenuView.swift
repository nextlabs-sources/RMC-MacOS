//
//  NXFileMenuView.swift
//  skyDRM
//
//  Created by bill.zhang on 2/28/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXFileMenuView: NSView {

    let operationTitles = [NXFileOperation.downloadFile:"Download",
                           NXFileOperation.protectFile : "Protect",
                           NXFileOperation.shareFile :"Share",
                           NXFileOperation.viewProperty : "View File Info",
                           NXFileOperation.deleteFile : "Delete",
                           NXFileOperation.logProperty : "View Activity",
                           
                           NXFileOperation.viewDetails: "Details",
                           NXFileOperation.viewManage: "Manage"]
    
    let operationImages = [NXFileOperation.downloadFile : NSImage(named: "download"),
                           NXFileOperation.protectFile : NSImage(named: "protectinmenu"),
                           NXFileOperation.shareFile : NSImage(named:  "shareinmenu"),
                           NXFileOperation.viewProperty : NSImage(named: "fileinfomenu"),
                           NXFileOperation.deleteFile: NSImage(named: "deleteinmenu"),
                           NXFileOperation.logProperty: NSImage(named: "filelogmenu"),
                           
                           NXFileOperation.viewDetails: NSImage(named:  "filedetailsmenu"),
                           NXFileOperation.viewManage: NSImage(named:  "filemanagemenu")]
    
    weak var delegate: NXFileOperationDelegate? = nil
    
    var fileItem: NXFileBase? {
        didSet {
            self.commonInit()
        }
    }
    
    var defaultOperations : [NXFileOperation]?
    var candidateOperations : [NXFileOperation]?
    var favOffOperations:[[NXFileOperation : Bool]] = [[NXFileOperation : Bool]]()
    
    var contextMenu : NXContextMenu?
    
    var moreBtn: NSButton?
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    @objc public func buttonClicked(sender:NSButton){
        if sender.tag == -1 {
            delegate?.nxFileOperation(type: .doNothing)
            
            contextMenu = NXContextMenu(operations: candidateOperations!, onOffOperation:favOffOperations)
            contextMenu?.operationDelegate = self
            contextMenu?.popUp(positioning:contextMenu?.item(at: 0), at: NSPoint(x: 10, y: 30), in: sender)
            
            return
        }
        
        delegate?.nxFileOperation(type: NXFileOperation(rawValue: sender.tag)!)
    }
    
    private func doWorkWithOperations() {
        var hasmore : CGFloat = 0
        if (fileItem?.isKind(of: NXFolder.self))! ||
            (fileItem?.isKind(of: NXProjectFolder.self))! {
            self.moreBtn = nil
        } else {
            if let moreOperations = candidateOperations,
                !moreOperations.isEmpty {
                let button = createButton(image: NSImage(named: "more")!)
                button.tag = -1
                let rect = NSRect(x: self.frame.size.width - 28, y: 5, width: 30, height: 30)
                button.frame = rect;
                button.layer?.backgroundColor = CGColor(gray: 0, alpha: 0)
                button.layer?.frame = CGRect(x: self.frame.size.width - 25, y: 10, width: 15, height: 15)
                button.layer?.cornerRadius = button.frame.width/2
                button.isBordered = false
                button.imageScaling = .scaleNone
                self.addSubview(button)
                hasmore = 1.0
                
                self.moreBtn = button
            }
            
        }
        
        if let operations = defaultOperations {
            for (index, element) in operations.enumerated() {
                let button = createButton(image: operationImages[element as NXFileOperation]!!)
                button.tag = element.rawValue
                let rect = NSRect(x: self.frame.size.width - (CGFloat(index) + 1 + hasmore)*25, y: 10, width: 20, height: 20)
                button.frame = rect
                button.layer?.backgroundColor = CGColor(gray: 0, alpha: 0)
                button.isBordered = false
                
                switch element {
                case .viewProperty:
                    button.toolTip = "View File Info"
                case .protectFile:
                    button.toolTip = "Protect"
                case .shareFile:
                    button.toolTip = "Share"
                case .deleteFile:
                    button.toolTip = "Delete"
                case .logProperty:
                    button.toolTip = "View Activity"
                case .viewDetails:
                    button.toolTip = "Details"
                case .viewManage:
                    button.toolTip = "Manage"
                case .downloadFile:
                    button.toolTip = "Download"
                default:
                    break;
                }
                
                self.addSubview(button)
            }

        }
    }
    
    private func createButton(image:NSImage)->NSButton {
        let button = NSButton()
        button.image = image
        button.target = self
        button.action = #selector(buttonClicked)
        button.setButtonType(.momentaryPushIn)
        button.bezelStyle = .roundedDisclosure
        button.imageScaling = .scaleAxesIndependently
        button.wantsLayer = true
        return button
    }
    
    private func commonInit() {
        self.subviews.forEach { $0.removeFromSuperview() }
        if fileItem == nil  {
            return
        }
        
        if fileItem is NXFolder {
            if NXCommonUtils.is3rdRepo(node: fileItem!){
                defaultOperations = []
            }else{
                defaultOperations = [NXFileOperation.deleteFile]
            }
            candidateOperations = []
        } else if fileItem is NXProjectFolder {
            if NXCommonUtils.is3rdRepo(node: fileItem!) || !NXSpecificProjectData.shared.getProjectInfo().ownedByMe{
                defaultOperations = []
            }else{
                defaultOperations = [NXFileOperation.deleteFile]
            }
            candidateOperations = []
        }else if let file = fileItem as? NXNXLFile {
            
            // delete > revoke > protect > normal
            if file.isDeleted == true  {
                defaultOperations = [NXFileOperation.logProperty, NXFileOperation.viewDetails]
                candidateOperations = [NXFileOperation.viewProperty]
            } else if file.isRevoked == true {
                defaultOperations = [NXFileOperation.logProperty, NXFileOperation.viewDetails]
                candidateOperations = [NXFileOperation.viewProperty, NXFileOperation.downloadFile, NXFileOperation.deleteFile]
            } else if file.isShared == false { // protect files
                defaultOperations = [NXFileOperation.logProperty, NXFileOperation.shareFile]
                candidateOperations = [NXFileOperation.viewProperty, NXFileOperation.downloadFile, NXFileOperation.deleteFile]
            } else {
                defaultOperations = [NXFileOperation.logProperty, NXFileOperation.viewManage]
                candidateOperations = [NXFileOperation.viewProperty, NXFileOperation.downloadFile, NXFileOperation.deleteFile]
            }
            
        } else if let file = fileItem as? NXSharedWithMeFile {
            
            if let rights = file.rights {
                var operations = [NXFileOperation]()
                
                operations.append(.viewProperty)
                if rights.contains(.share) || file.getIsOwner() {
                    operations.append(.shareFile)
                }
                if rights.contains(.saveAs) || file.getIsOwner() {
                    operations.append(.downloadFile)
                }
                
                defaultOperations = Array(operations.prefix(2))
                if operations.count > 2 {
                    candidateOperations = Array(operations.suffix(from: 2))
                } else {
                    candidateOperations = []
                }
            }
            
        } else if (fileItem?.isKind(of: NXProjectFile.self))! {
            if NXSpecificProjectData.shared.getProjectInfo().ownedByMe {
                defaultOperations = [NXFileOperation.logProperty, NXFileOperation.viewProperty]
                candidateOperations = [NXFileOperation.downloadFile, NXFileOperation.deleteFile]
            }else{
                defaultOperations = [NXFileOperation.downloadFile, NXFileOperation.viewProperty]
            }
        } else if (fileItem?.isKind(of: NXFile.self))! {
            defaultOperations = [NXFileOperation.protectFile, NXFileOperation.shareFile]
            if NXCommonUtils.is3rdRepo(node: fileItem!){
                if NXCommonUtils.isNXLFile(path: (fileItem!.localPath != "") ? fileItem!.localPath : fileItem!.name) {
                    candidateOperations = [NXFileOperation.viewProperty]
                }else{
                    candidateOperations = []
                }
                
            }else{
                candidateOperations = [NXFileOperation.viewProperty, NXFileOperation.downloadFile, NXFileOperation.deleteFile]
                if NXCommonUtils.isNXLFile(path: (fileItem!.localPath != "") ? fileItem!.localPath : fileItem!.name) {
                    candidateOperations?.append(NXFileOperation.logProperty)
                }
            }
        }
        
        ////////////////////////////////////////////////////////////////////////////////
        // fav operation
        favOffOperations.removeAll()
        if fileItem?.boundService?.serviceType == ServiceType.kServiceSkyDrmBox.rawValue {
            if (fileItem?.isFavorite)! {
                favOffOperations.append([NXFileOperation.markFavorite : true])
            } else {
                favOffOperations.append([NXFileOperation.markFavorite : false])
            }
        } else if let file = fileItem as? NXNXLFile,
            file.isDeleted == false {
            if (fileItem?.isFavorite)! {
                favOffOperations.append([NXFileOperation.markFavorite : true])
            } else {
                favOffOperations.append([NXFileOperation.markFavorite : false])
            }
        }
        
        ////////////////////////////////////////////////////////////////////////////////
        
        doWorkWithOperations()
    }
}

extension NXFileMenuView : NXFileOperationDelegate {
    func nxFileOperation(type: NXFileOperation) {
        delegate?.nxFileOperation(type:type)
    }
}

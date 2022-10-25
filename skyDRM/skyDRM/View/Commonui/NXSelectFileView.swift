//
//  NXSelectFileView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/18.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

enum NXSelectedFile {
    case localFile(url: URL)
    case repositoryFile(file: NXFileBase?)
    
    var url: URL? {
        get {
            switch self {
            case .localFile(let url):
                return url
            default:
                return nil
            }
        }
    }
}

protocol NXSelectFileViewDelegate: NSObjectProtocol {
    func onFileClick(file: NXFileBase)
    func onSelectChange(bSelected: Bool)
}

@IBDesignable class NXSelectFileView: NSView {
    @IBOutlet weak var browserImage: NSImageView!
    @IBOutlet weak var browserLabel: NSTextField!
    @IBOutlet weak var browserStack: NXMouseEventStackView!

    @IBOutlet weak var repositoriesOutline: NSOutlineView!
    @IBOutlet weak var contentView: NSView!
    var selectedFile: NXSelectedFile? {
        get {
            var file: NXSelectedFile?
            if isLocalView {
                if let fileUrl = localFileView?.fileURL  {
                    file = .localFile(url: fileUrl)
                }
            }
            else {
                if let selectedFile = tableView?.selectedFile {
                    file = .repositoryFile(file: selectedFile)
                }
            }
            return file
        }
    }
    var actionDescription = "" {
        didSet {
            localFileView?.actionDescription = actionDescription
        }
    }
    private var localFileView: NXUploadLocalView?
    fileprivate var tableView: NXSelectFileTableView?
    fileprivate var isLocalView = true {
        willSet {
            if newValue == true {
                currentSelectedRow = -1
                repositoriesOutline.reloadData()
                showBrowserView()
                browserLabel.textColor = NSColor(red: 57.0 / 255, green: 150.0 / 255, blue: 73.0 / 255, alpha: 1)
                browserStack.layer?.backgroundColor = NSColor(calibratedWhite: 0.82, alpha: 1.0).cgColor
                browserImage.image = NSImage(named:  "localfiles")
            }
            else {
                showTableView()
                browserLabel.textColor = NSColor.black
                browserStack.layer?.backgroundColor = NSColor.white.cgColor
                browserImage.image = NSImage(named: "localfiles_grey")
            }
        }
    }
    fileprivate var connectedBoundSerives = [NXBoundService]()
    fileprivate var currentSelectedRow = -1 {
        willSet {
            changeRowSelection(row: currentSelectedRow, selected: false)
            changeRowSelection(row: newValue, selected: true)
        }
    }
    fileprivate var displayFiles = [NXFileBase]()
    
    weak var delegate: NXSelectFileViewDelegate?
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview else {
            return
        }
        wantsLayer = true
        layer?.backgroundColor = NSColor(red: 242.0 / 255, green: 243.0 / 255, blue: 245.0 / 255, alpha: 1).cgColor
        browserStack.wantsLayer = true
        browserStack.layer?.cornerRadius = 1
        browserStack.mouseDelegate = self
        isLocalView = true
        
        repositoriesOutline.dataSource = self
        repositoriesOutline.delegate = self
        
        let selectTypes: [ServiceType] = [.kServiceDropbox, .kServiceSharepointOnline, .kServiceOneDrive, .kServiceGoogleDrive, .kServiceSkyDrmBox]
        if let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId {
            let services = CacheMgr.shared.getAllBoundService(userId: userId)
            for service in services {
                if service.boundService.serviceIsAuthed == true,
                    let type = ServiceType(rawValue: service.boundService.serviceType),
                    selectTypes.contains(type){
                    connectedBoundSerives.append(service.boundService)
                }
            }
            repositoriesOutline.reloadData()
        }
    }
  
    fileprivate func changeRowSelection(row: Int, selected: Bool) {
        guard row >= 0,
            let view = repositoriesOutline.rowView(atRow: row, makeIfNecessary: false),
            let imageView = view.viewWithTag(2) as? NSImageView,
            let text = view.viewWithTag(1) as? NSTextField,
            let item = repositoriesOutline.item(atRow: row) as? NXBoundService else {
            return
        }
        if selected {
            view.wantsLayer = true
            view.backgroundColor = BK_COLOR
            let name = NXCommonUtils.getCloudDriveIconForSelected(cloudDriveType: item.serviceType)
            imageView.image = NSImage(named:  name)
            text.textColor = NSColor(red: 57.0 / 255, green: 150.0 / 255, blue: 73.0 / 255, alpha: 1)
        }
        else {
            view.wantsLayer = true
            view.backgroundColor = NSColor.white
            let name = NXCommonUtils.getCloudDriveIconForUnselected(cloudDriveType: item.serviceType)
            imageView.image = NSImage(named:  name)
            text.textColor = NSColor.black
        }
        
    }
    fileprivate func getFilesUnderRoot(bs: NXBoundService) {
        let root = NXFolder()
        CacheMgr.shared.getFilesUnderRoot(bs: bs, root: root)
        if let displayFiles = root.getChildren() as? [NXFileBase] {
            self.displayFiles = displayFiles
        }
        else {
            self.displayFiles.removeAll()
        }
    }
    fileprivate func getFilesUnderFolder(folder: NXFileBase) {
        CacheMgr.shared.getFilesUnderFolder(folder: folder)
        if let displayFiles = folder.getChildren() as? [NXFileBase] {
            self.displayFiles = displayFiles
        }
        else {
            self.displayFiles.removeAll()
        }
    }
    
    private func showBrowserView() {
        tableView?.removeFromSuperview()
        localFileView = NXCommonUtils.createViewFromXib(xibName: "NXUploadLocalView", identifier: "uploadLocalView", frame: nil, superView: contentView) as? NXUploadLocalView
        localFileView?.actionDescription = actionDescription
        localFileView?.delegate = self
        tableView = nil
        delegate?.onSelectChange(bSelected: false)
    }
    private func showTableView() {
        localFileView?.removeFromSuperview()
        tableView = NXCommonUtils.createViewFromXib(xibName: "NXSelectFileTableView", identifier: "selectFileTableView", frame: nil, superView: contentView) as? NXSelectFileTableView
        tableView?.delegate = self
        localFileView = nil
        delegate?.onSelectChange(bSelected: false)
    }
}

extension NXSelectFileView: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        return connectedBoundSerives.count
    }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return connectedBoundSerives[index]
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
}

extension NXSelectFileView: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let bs = item as? NXBoundService,
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "repositoryCell"), owner: self) as? NSTableCellView,
            let imageView = view.viewWithTag(2) as? NSImageView,
            let text = view.viewWithTag(1) as? NSTextField else {
            return nil
        }
        let unselectedIcon = NXCommonUtils.getCloudDriveIconForUnselected(cloudDriveType: bs.serviceType)
        imageView.image = NSImage(named: unselectedIcon)
        text.stringValue = bs.serviceAlias
        text.toolTip = bs.serviceAlias
        return view
    }
    func outlineViewSelectionDidChange(_ notification: Notification) {
        //prevent empty selection, change selection type is bad solution
        if repositoriesOutline.selectedRow == -1 {
            repositoriesOutline.selectRowIndexes([currentSelectedRow], byExtendingSelection: false)
            return
        }
        if repositoriesOutline.selectedRow == currentSelectedRow {
            return
        }
        
        isLocalView = false
        currentSelectedRow = repositoriesOutline.selectedRow
        
        guard let bs = repositoriesOutline.item(atRow: currentSelectedRow) as? NXBoundService else {
            return
        }
        getFilesUnderRoot(bs: bs)
        tableView?.rootName = bs.serviceAlias
        tableView?.files = displayFiles

    }
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        let myCustomView = NXRepoTableRow()
        return myCustomView
    }
}

extension NXSelectFileView: NXSelectFileTableViewDelegate {
    func onClick(file: NXFileBase?) {
        if let file = file {
            if file is NXFolder {
                getFilesUnderFolder(folder: file)
                tableView?.files = displayFiles
            }
            else {
                delegate?.onFileClick(file: file)
            }
        }
        else {
            guard let bs = repositoriesOutline.item(atRow: currentSelectedRow) as? NXBoundService else {
                return
            }
            getFilesUnderRoot(bs: bs)
            tableView?.files = displayFiles
        }
    }
    func onSelectChange(bSelected: Bool) {
        delegate?.onSelectChange(bSelected: bSelected)
    }
}

extension NXSelectFileView: NXUploadLocalViewDelegate {
    func onLocalFileSelectChange(bSelected: Bool) {
        delegate?.onSelectChange(bSelected: bSelected)
    }
}

extension NXSelectFileView: NXMouseEventStackViewDelegate {
    func mouseDownStackView(sender: Any, event: NSEvent) {
        if isLocalView == false {
            isLocalView = true
        }
    }
}

//
//  NXTrayMainView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 31/10/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXTrayManageViewDelegate: NSObjectProtocol {
    func closePopover()
}

class NXTrayManageView: NSView {
    @IBOutlet weak var circleText: NXCircleText!
    
    @IBAction func emptyImageView(_ sender: NSImageView) {
    }
    @IBOutlet weak var nameLabel: NSTextField!
    @IBOutlet weak var usageLabel: NSTextField!
    @IBOutlet weak var networkStatusContainer: NSView!
    
    @IBOutlet weak var scrollView: NSScrollView!
    @IBOutlet weak var outlineView: NSOutlineView!
    
    @IBOutlet weak var manageBtn: NXMouseEventButton!
    @IBOutlet weak var emptyView: NSView!
    @IBOutlet weak var trayHelpContainer: NSView!
    
    @IBOutlet weak var openMainWindowButton: NXMouseEventButton!
    
    @IBOutlet weak var openWebPageButton: NXMouseEventButton!
    private var networkStatusView: NXNetworkStatusView?
    private var trayHelpView: NXTrayHelpView?
    
    fileprivate let moreMenu = NXTrayContextMenu()
    fileprivate var oldSelectedRow: Int = -1
    
    weak var delegate: NXTrayManageViewDelegate?
    
    public var isOffline = false {
        didSet {
            networkStatusView?.isOffline = isOffline
        }
    }
    
    fileprivate var records = [NXFileRecord]()
    
    @IBOutlet weak var topFromStatusToList: NSLayoutConstraint!
    
    @IBAction func onOpenMainWindow(_ sender: Any) {
        if !trayHelpContainer.isHidden {
            removeHelpView()
        }
        
        NXWindowsManager.sharedInstance.openMainWindow()
        delegate?.closePopover()
        
    }
    
    @IBAction func onMoreClicked(_ sender: Any) {
        if let event = window?.currentEvent {
            let mousePoint = convert(event.locationInWindow, from: nil)
            moreMenu.popUp(positioning: moreMenu.item(at: 0), at: mousePoint, in: self)
        }
    }
    
    @IBAction func onOpenWebsite(_ sender: Any) {
        NXCommonUtils.openWebsite()
        delegate?.closePopover()
    }
    @IBAction func openPreference(_ sender: Any) {
        onPreferences()
    }
    
    override func viewWillMove(toWindow newWindow: NSWindow?) {
        super.viewWillMove(toWindow: window)
        
        if newWindow == nil {
            return
        }
        
        addObserver()
         NXDBManager.sharedInstance.removeExpiredFileRecord()
        records = NXTrayViewNotificationManager.shared.getFileRecords()
        YMLog("tray:will move \(records.count)")
    }
    
    deinit {
        removeObserver()
    }
    
    open func updateUI(){
    records.removeAll() 
    records = NXTrayViewNotificationManager.shared.getFileRecords()
    YMLog("viewWillAppear:update: \(records.count)")
    self.outlineView.reloadData()
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        
        guard let _ = self.window else {
            return
        }
        
        checkTrayHelpView()
        
        networkStatusView = NXCommonUtils.createViewFromXib(xibName: "NXNetworkStatusView", identifier: "networkStatusView", frame: nil, superView: networkStatusContainer) as? NXNetworkStatusView
        
        trayHelpView = NXCommonUtils.createViewFromXib(xibName: "NXTrayHelpView", identifier: "helpView", frame: nil, superView: trayHelpContainer) as? NXTrayHelpView
        trayHelpView?.delegate = self
        
        NXClient.getCurrentClient().getStorage { (result, error) in
            if let value = result {
                let storage = NXMyDriveStorage(used: 0, total: Int64(value.quota), myvault: Int64(value.usage))
                NXClientUser.shared.storage = storage
            }
        }
        
        if let user = NXClientUser.shared.user {
            let displayName = user.name
            nameLabel.stringValue = user.name
            circleText.text = NXCommonUtils.abbreviation(forUserName: displayName)
            circleText.extInfo = user.email
            
            let abbrevStr = NXCommonUtils.abbreviation(forUserName: displayName)
            let index = displayName.index(displayName.startIndex, offsetBy: 1)
            let firstStr = String(abbrevStr[..<index])
            if let colorHexValue = NXCommonUtils.circleViewBKColor[firstStr]{
                circleText.backgroundColor = NSColor(colorWithHex: colorHexValue, alpha: 1.0)!
            }
        }
        
        outlineView.wantsLayer = true
        outlineView.backgroundColor = NSColor.white
        outlineView.dataSource = self
        outlineView.delegate = self
        outlineView.selectionHighlightStyle = .none
        
        moreMenu.initCommonControl()
        moreMenu.actionDelegate = self
        
        emptyView.wantsLayer = true
        emptyView.layer?.backgroundColor = NSColor.white.cgColor
        
        openMainWindowButton.toolTip = "BUTTON_TOOPTIP_OPEN_SkyDRM_DESKTOP".localized
        openWebPageButton.toolTip = "BUTTON_TOOPTIP_OPEN_SKYDRM_WEB".localized
        manageBtn.toolTip =  "BUTTON_TOOPTIP_OPTIONS".localized
    }
}

// MARK: Notifications.

extension NXTrayManageView {
    fileprivate func addObserver() {
         NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .trayViewUpdated)
    }
    
    fileprivate func removeObserver() {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc fileprivate func observeNotification(_ notification: Notification) {
        if notification.nxNotification == .trayViewUpdated {
            records.removeAll()
            records = NXTrayViewNotificationManager.shared.getFileRecords()
            YMLog("tray:notify: \(records.count)")
            self.outlineView.reloadData()
        }
    }
    
    
}

// MARK: - Records.

extension NXTrayManageView {
    
    fileprivate func isRecordExist(_ record: NXFileRecord) -> Bool {
        for r in self.records {
            if r == record {
                return true
            }
        }
        
        return false
    }
    
    func addOrUpdateRecord(_ record: NXFileRecord) {
        if isRecordExist(record) {
            updateRecord(record)
        } else {
            addRecord(record)
        }
    }
    
    func updateRecord(_ record: NXFileRecord) {
        for (index, r) in self.records.enumerated() {
            if record == r {
                if r.fileStatus != record.fileStatus {
                    r.fileStatus = record.fileStatus
                    self.outlineView.reloadData(forRowIndexes: [index], columnIndexes: [0])
                    NXDBManager.sharedInstance.updateFileRecord(record)
                }
                break
            }
        }
        
    }
    
    func addRecord(_ record: NXFileRecord) {
        self.records.insert(record, at: 0)
        self.outlineView.reloadData()
        NXDBManager.sharedInstance.addFileRecord(record)
        
    }
    
    func removeRecord(_ record: NXFileRecord) {
        for (index, r) in self.records.enumerated() {
            if record == r {
                self.records.remove(at: index)
                self.outlineView.reloadData()
                NXDBManager.sharedInstance.removeFileRecord(record)
                break
            }
        }
    }
    
}

extension NXTrayManageView {
    public func setStorage(myvault: Int64, total: Int64) {
        let myVaultStr = NXCommonUtils.formatFileSize(fileSize: myvault, precision: 1)
        let totalStr = NXCommonUtils.formatFileSize(fileSize: total, precision: 1)
        usageLabel.stringValue = String(format: NSLocalizedString("HOME_TOPVIEW_INDICATORVIEW_USED_PERCENTAGE", comment: ""), myVaultStr, totalStr)
    }
    
    
    func checkTrayHelpView() {
        //        NXCommonUtils.saveShowGuide(isShow: true)
        if !NXCommonUtils.loadShowGuide() {
            topFromStatusToList.constant = 0
            trayHelpContainer.isHidden = true
        }
        
        if records.count > 0
        {
            topFromStatusToList.constant = 0
            trayHelpContainer.isHidden = true
        }else{
            topFromStatusToList.constant = 0
            trayHelpContainer.isHidden = false
        }
    }
    
    func checkIsListEmpty() {
        if records.isEmpty {
            self.scrollView.isHidden = true
            //self.scrollView.isHidden = true
            //self.emptyView.isHidden = false
            //self.syncStatusView?.isHidden = true
        } else {
            self.scrollView.isHidden = false
            //self.emptyView.isHidden = true
            //self.syncStatusView?.isHidden = false
        }
    }
}

extension NXTrayManageView: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        checkIsListEmpty()
        return records.count
    }
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        return records[index]
    }
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        return false
    }
}

extension NXTrayManageView: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        guard let record = item as? NXFileRecord,
            let view = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SyncFileCell"), owner: self) as? NSTableCellView,
            let fileTypeImage = view.viewWithTag(1) as? NSImageView,
            let fileNameLabel = view.viewWithTag(2) as? NSTextField,
            let failedLbl = view.viewWithTag(3) as? NSTextField,
            let syncStateLabel = view.viewWithTag(100) as? NXImageLabel,
            let syncStateImage = view.viewWithTag(4) as? NSImageView else {
            return nil
        }
        
        let filename = record.filename
        var image: NSImage?
        let fileExtension = NXCommonUtils.getOriginFileExtension(filename: filename)
            switch record.type {
            case.upload:
                if let status = record.fileStatus {
                    switch status {
                        case .waiting:
                            let name = "\(fileExtension)_w"
                                image = NSImage.init(named: name)
                            if image == nil {
                                image = NSImage(named: "- - -_w")
                        }
                        case .pending:
                            let name = "\(fileExtension)_w"
                            image = NSImage.init(named:name)
                            if image == nil {
                                image = NSImage(named:"- - -_w")
                            }
                        case .syncing:
                            let name = "\(fileExtension)_u"
                            image = NSImage.init(named:name)
                            if image == nil {
                                image = NSImage(named: "- - -_u")
                            }
                        case .completed:
                            let name = "\(fileExtension)_d"
                            image = NSImage.init(named:  name)
                            if image == nil {
                                image = NSImage(named: "- - -_d")
                            }
                        case .failed:
                            let name = "\(fileExtension)_w"
                            image = NSImage.init(named:  name)
                            if image == nil {
                                image = NSImage(named: "- - -_w")
                                }
                            }
                    }
            case .download:
                if let status =  record.fileStatus {
                switch status {
                    case .pending:
                        let name = "\(fileExtension.uppercased())_G"
                        image = NSImage.init(named: name)
                        if image == nil {
                            image = NSImage(named: "---_g")
                        }
                        fileTypeImage.imageAlignment = .alignRight
                    case .syncing:
                        let name = "\(fileExtension)_u"
                        image = NSImage.init(named:  name)
                        if image == nil {
                            image = NSImage(named:"- - -_u")
                        }
                    case .completed:
                        let name = "\(fileExtension)_o"
                        image = NSImage.init(named: name)
                        if image == nil {
                            image = NSImage(named:  "- - -_o")
                        }
                    case .failed:
                        let name = "\(fileExtension)_w"
                        image = NSImage.init(named:  name)
                        if image == nil {
                            image = NSImage(named: "- - -_w")
                        }
                    case .waiting:
                    let name = "\(fileExtension)_w"
                    image = NSImage.init(named: name)
                    if image == nil {
                        image = NSImage(named: "- - -_w")
                    }
                    }
                }
            case.systembucketProtect:
                let name = "\(fileExtension)_d"
                image = NSImage.init(named:  name)
                if image == nil {
                    image = NSImage(named: "- - -_d")
                }
            default:
                    let name = "\(fileExtension)_o"
                    image = NSImage.init(named:  name)
                    if image == nil {
                        image = NSImage(named:  "- - -_o")
                        
                    }
        }
        fileTypeImage.isHidden = false
        fileTypeImage.image = image
        fileNameLabel.stringValue = filename
        failedLbl.isHidden = true
        syncStateLabel.isHidden = false
        switch record.type {
        case .remove:
            syncStateLabel.image = nil
            syncStateImage.isHidden = true
            syncStateLabel.stringValue = "Removed from local".localized
        case .upload:
            if let status = record.fileStatus {
                switch status {
                case .pending:
                    syncStateImage.isHidden = true
                    syncStateLabel.image = NSImage(named:"uploading_sign")
                    syncStateLabel.stringValue = "UPLOAD_WAITING".localized
                case .syncing:
                    syncStateImage.isHidden = true
                    syncStateLabel.image = NSImage(named:  "uploading_sign")
                    syncStateLabel.stringValue = "UPLOAD_DOING".localized
                case .failed:
                    syncStateImage.isHidden = false
                    syncStateImage.image = NSImage(named:  "status_error")
                    syncStateLabel.isHidden = true
                    failedLbl.isHidden = false
                    failedLbl.stringValue = "TRAY_CANNOT_CONNECT".localized
                case .completed:
                    syncStateImage.isHidden = false
                    syncStateImage.image = NSImage(named: "status_completed")
                    syncStateLabel.image = nil
                    syncStateLabel.stringValue = "UPLOAD_SUCCESSFUL".localized
                case .waiting:
                    syncStateImage.isHidden = false
                    syncStateImage.isHidden = true
                    syncStateLabel.image = NSImage(named:  "uploading_sign")
                    syncStateLabel.stringValue = "UPLOAD_WAITING".localized
                }
            }
        case .download:
            if let status = record.fileStatus {
                switch status {
                case .pending:
                    // Download no pause, only failed.
                    syncStateImage.isHidden = false
                    syncStateImage.image = NSImage(named:"status_error")
                    syncStateLabel.isHidden = true
                    failedLbl.isHidden = false
                    failedLbl.stringValue = "DOWNLOAD_FAILED".localized
                    
                case .syncing:
                    syncStateImage.isHidden = true
                    syncStateLabel.image = NSImage(named:  "download")
                    syncStateLabel.stringValue = "DOWNLOAD_DOING".localized
                case .failed:
                    syncStateImage.isHidden = false
                    syncStateImage.image = NSImage(named:"status_error")
                    syncStateLabel.isHidden = true
                    failedLbl.isHidden = false
                    failedLbl.stringValue = "DOWNLOAD_FAILED".localized
                case .completed:
                    syncStateImage.isHidden = false
                    syncStateImage.image = NSImage(named: "status_completed")
                    syncStateLabel.image = nil
                    syncStateLabel.stringValue = "DOWNLOAD_SUCCESSFUL".localized
                    
                case .waiting:
                    syncStateImage.isHidden = false
                    syncStateImage.image = NSImage(named:"status_error")
                    syncStateLabel.isHidden = true
                    failedLbl.isHidden = false
                    failedLbl.stringValue = "TRAY_CANNOTCONNECT".localized
                }
            }
          case.systembucketProtect:
            syncStateImage.isHidden = false
            syncStateImage.image = NSImage(named: "status_completed")
            syncStateLabel.image = nil
            syncStateLabel.stringValue = "SYSTEMBUCKET_PROTECT_SUCCESSFUL".localized
        }
        
        return view
    }
}

extension NXTrayManageView: NXTrayContextMenuDelegate {
    func onAbout() {
        delegate?.closePopover()
        NXHelpPageWindowController.shared.showWindow()
        
        
    }
    func onHelp() {
        if let url = URL(string: "https://help.skydrm.com/docs/mac/help/1.0/en-us/index.htm") {
            NSWorkspace.shared.open(url)
        }
        delegate?.closePopover()
    }
    func onFeedback() {
       
        let vc = NXFeedbackViewController()
        self.window?.contentViewController?.presentAsModalWindow(vc)
        delegate?.closePopover()
        delegate?.closePopover()
        
    }
    func onPreferences() {
       
       let vc = NXPreferencesViewController()
        self.window?.contentViewController?.presentAsModalWindow(vc)
        delegate?.closePopover()
        
    }
    func onLogout() {
        delegate?.closePopover()
        
        NXFileMenuAction.shared.signout()
    }
}

extension NXTrayManageView: NXTrayHelpViewDelegate {
    func removeHelpView() {
        NXCommonUtils.saveShowGuide(isShow: false)
        checkTrayHelpView()
        self.needsDisplay = true
    }
}

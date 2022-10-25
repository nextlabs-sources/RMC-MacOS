//
//  NXActivityLogViewController.swift
//  skyDRM
//
//  Created by xx-huang on 14/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXActivityLogViewController: NSViewController {

    fileprivate struct Constant {
        static let activityColumnIdentifier = "ActivityColumn"
        static let timeColumnIdentifier = "TimeColumn"
        
        static let allowImageName = "Allow"
        static let denyImageName = "Deny"
        
        static let notStewardWarningMessage = NSLocalizedString("ERROR_IS_NOT_STEWARD", comment: "")
        
        static let maxPageCount = 50
        
        static let GetLogWarningMessage = NSLocalizedString("ERROR_CAN_NOT_GET_ACTIVITY_LOG", comment: "")
    }
    
    // Input
    var file: NXFileBase?
    
    // View
    @IBOutlet weak var activityTableView: NSTableView!
    @IBOutlet weak var fileNameTextField: NSTextField!
    var waitingView: NXWaitingView?
    
    // Data
    var activityLogData = NSMutableArray() //[NXActivityLogInfoModel]()
    fileprivate var curSortDescriptor: [NSSortDescriptor]? = nil
    
    var duid: String?
    var isLoading: Bool = false
    var hasMoreData: Bool = true
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        initView()
        
        fileNameTextField.stringValue = file?.name ?? ""
        
        /// get duid
        if file is NXNXLFile || file is NXProjectFile {
            self.duid = file?.getNXLID()
            sendRequestForLogList(with: 0)
            
        } else {
            downloadFile()
        }
        
        NotificationCenter.default.addObserver(self, selector: #selector(tableViewDidScroll), name: NSView.boundsDidChangeNotification, object: activityTableView.enclosingScrollView?.contentView)
    }
    
    @objc func tableViewDidScroll(notification: NSNotification) {
        
        guard let clipView = notification.object as? NSClipView else {
            return
        }
        
        let maxY = clipView.visibleRect.maxY
        let contentHeight = activityTableView.bounds.height
        
        if maxY > contentHeight {
            print("hit bottom")
            
            if !isLoading && hasMoreData {
                sendRequestForLogList(with: activityLogData.count)
            }
        }
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        self.view.window?.styleMask = .borderless
        addSortDescriptor()
    }
    
    private func initView() {
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.white.cgColor

        // No use
        
        creatingWaitingView()

    }
    
    private func creatingWaitingView() {
        waitingView = NXCommonUtils.createWaitingView(superView: self.activityTableView)
        waitingView?.isHidden = true
    }
    
    fileprivate func sendRequestForLogList(with start: Int) {
        guard let duid = self.duid else {
            return
        }
        
        guard
            let userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId),
            let ticket = (NXLoginUser.sharedInstance.nxlClient?.profile.ticket)
            else { return }
        
        
        waitingView?.isHidden = false
        isLoading = true
        
        let logService = NXLogService(userID: userId, ticket: ticket)
        logService.delegate = self
        
        let filter = NXActivityLogInfoFilter(start: "\(start)",
                                             count: "\(Constant.maxPageCount)",
                                             orderBy: [NXActivityLogSortType.accessTime],
                                             searchField: [NXActivityLogInfoSearchFieldType.email],
                                             searchText: "",
                                             orderByReverse: "true")
        
        logService.listActivityLogInfoWith(duid: duid, filter: filter)
    }
    
    private func addSortDescriptor() {
        // handle sort
        for col in activityTableView.tableColumns {
            if (col.identifier.rawValue == Constant.timeColumnIdentifier)
            {
                let sort = NSSortDescriptor(key: "accessTime", ascending: true)
                col.sortDescriptorPrototype = sort
            }
        }
        
        curSortDescriptor = [NSSortDescriptor(key: "accessTime", ascending: false)]
    }
    
    @IBAction func close(_ sender: Any) {
        closeWindow()
    }
    
    fileprivate func closeWindow() {
        self.presentingViewController?.dismiss(self)
    }
    
    func downloadFile() {
        
        guard let file = file else {
            return
        }
        
        waitingView?.isHidden = false
        
        let data = downloadData(file: file, Path: "", fileSource: .other, needOpen: false)
        let result = DownloadUploadMgr.shared.downloadFile(file: file, filePath: nil, delegate: self, data: data)
        if !result.0 {
            waitingView?.isHidden = true
            let message = NSLocalizedString("FILE_OPERATION_DOWNLOAD_FAILED", comment:"")
            NSAlert.showAlert(withMessage: message, informativeText: "") {
                _ in
                self.closeWindow()
            }
            return
        }
    }
}

extension NXActivityLogViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return activityLogData.count
    }
    
}

extension NXActivityLogViewController: NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        
        let logModel = activityLogData.object(at: row) as! NXActivityLogInfoModel
        
        var cellView: NSView?
        if (tableColumn?.identifier)!.rawValue == Constant.activityColumnIdentifier {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.activityColumnIdentifier), owner: self) as? NXActivityLogCellView {
                
                let isAllow = (logModel.accessResult == "Allow") ? true: false
                cell.imageView?.image = isAllow ? NSImage(named: Constant.allowImageName): NSImage(named:  Constant.denyImageName)
                
                if let name = logModel.email, let operate = logModel.operation {
                    var lowerOperate = operate.lowercased()
                    let sentense: String = {
                        if isAllow {
                            if lowerOperate == "remove user" {
                                lowerOperate = "removed user"
                                return name + " has " + lowerOperate + " of the file"
                            } else if lowerOperate == "print" {
                                lowerOperate = "printed"
                                return name + " has " + lowerOperate + " the file"
                            } else if lowerOperate == "view" {
                                lowerOperate = "viewed"
                                return name + " has " + lowerOperate + " the file"
                            } else if lowerOperate == "revoke" {
                                lowerOperate = "revoked"
                                return name + " has " + lowerOperate + " the file"
                            } else if lowerOperate == "share" {
                                lowerOperate = "shared"
                                return name + " has " + lowerOperate + " the file"
                            } else if lowerOperate == "reshare" {
                                lowerOperate = "reshared"
                                return name + " has " + lowerOperate + " the file"
                            } else if lowerOperate == "protect" {
                                lowerOperate = "protected"
                                return name + " has " + lowerOperate + " the file"
                            } else if lowerOperate == "download" {
                                lowerOperate = "downloaded"
                                return name + " has " + lowerOperate + " the file"
                            } else {
                                return name + " has " + lowerOperate + " the file"
                            }
                        } else {
                            if lowerOperate == "remove user" {
                                return name + " has tried to " + lowerOperate + " of the file"
                            } else {
                                return name + " has tried to " + lowerOperate + " the file"
                            }
                        }
                    }()
                    
                    let sentenseStr = sentense as NSString
                    let operationRange = sentenseStr.range(of: lowerOperate)
                    let attributeStr = NSMutableAttributedString(string: sentense)
                    
                    
                    attributeStr.addAttribute(NSAttributedString.Key.foregroundColor, value: (isAllow) ? NSColor(colorWithHex: "#34994C", alpha: 1.0)!: NSColor(colorWithHex: "#EB5757", alpha: 1.0)!, range: operationRange)
                    cell.textField?.attributedStringValue = attributeStr
                }
                
                if let deviceType = logModel.deviceType, let deviceId = logModel.deviceId {
                    let attribute = [NSAttributedString.Key.foregroundColor: NSColor(colorWithHex: "#828282", alpha: 1.0)]
                    cell.fromTextField?.stringValue = deviceType + " - " + deviceId
                    cell.fromTextField.attributedStringValue = NSAttributedString(string: cell.fromTextField.stringValue, attributes: attribute as [NSAttributedString.Key : Any] )
                }
                
                cellView = cell
            }
            
            
        } else if (tableColumn?.identifier)!.rawValue == Constant.timeColumnIdentifier {
            if let cell = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: Constant.timeColumnIdentifier), owner: self) as? NSTableCellView {
                
                let formatter = DateFormatter()
                //formatter.locale = Locale.current
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "dd MMM yyyy,hh:mm a"
                formatter.amSymbol = "AM"
                formatter.pmSymbol = "PM"
    
                let date = NSDate(timeIntervalSince1970:logModel.accessTime)
                let time = formatter.string(from:date as Date)
    
                cell.textField?.stringValue = time
                
                cellView = cell
            }
            
        }
        
        return cellView
    }
    
    public func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]){
        Swift.print("sort: \(tableView.sortDescriptors)")
        
        curSortDescriptor = tableView.sortDescriptors
        activityLogData.sort(using: curSortDescriptor!)
        tableView.reloadData()
    }
}

extension NXActivityLogViewController:NXLogServiceDelegate{
    
    func getListActivityLogInfoFinished(activityLogInfoModel: [NXActivityLogInfoModel]?,
                                        fileName: String?,
                                        duid: String?,
                                        totalCount: Int,
                                        error: Error?)
    {
        
        waitingView?.isHidden = true
        isLoading = false
        
        if error != nil {
            NSAlert.showAlert(withMessage: Constant.GetLogWarningMessage, informativeText: "") {
                _ in
                self.closeWindow()
            }
            
            return
        }
        
        if let moreData = activityLogInfoModel {
            activityLogData.addObjects(from: moreData)
            activityTableView.reloadData()
            
            if activityLogData.count < totalCount {
                hasMoreData = true
            } else {
                hasMoreData = false
            }
        }
    }
    
}

extension NXActivityLogViewController: DownloadUploadMgrDelegate {
    func updateProgress(id: Int, data: Any?, progress: Float) {
    }

    func downloadUploadFinished(id: Int, data: Any?, error: NSError?) {
        
        waitingView?.isHidden = true
        
        if let data = data as? downloadData {
            if error != nil {
                try? FileManager.default.removeItem(atPath: data.Path)
                
                if error?.code != NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue {
                    var message = NSLocalizedString("FILE_OPERATION_DOWNLOAD_FAILED", comment:"")
                    
                    if error?.code == NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE.rawValue{
                        message = NSLocalizedString("FILE_OPERATION_DOWNLOAD_NO_SUCH_FILE", comment:"")
                    }
                    
                    NSAlert.showAlert(withMessage: message, informativeText: "") {
                        _ in
                        self.closeWindow()
                    }
                }
                return
            }
            
            if let file = file {
                let fileURL = URL(fileURLWithPath: file.localPath, isDirectory: false)
                NXLoginUser.sharedInstance.nxlClient?.getStewardForNXLFile(fileURL) {
                    steward, duid, error in
                    
                    if steward != NXLoginUser.sharedInstance.nxlClient?.profile.defaultMembership.id {
                        NSAlert.showAlert(withMessage: Constant.notStewardWarningMessage, informativeText: "") {
                            _ in
                            self.closeWindow()
                        }
                    }
                    
                    self.duid = duid
                    self.sendRequestForLogList(with: 0)
                    
                }
            }
            
            
        }
    }
}


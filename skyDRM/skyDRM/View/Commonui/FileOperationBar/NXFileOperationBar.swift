//
//  NXFileOperationBar.swift
//  skyDRM
//
//  Created by Kevin on 2017/2/7.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXFileOperationBar: NSView {

    @IBOutlet weak var uploadFileButton: NSButton!
    @IBOutlet weak var downloadFileButton: NSButton!
    @IBOutlet weak var pathControl: NSPathControl!
    @IBOutlet weak var gridViewButton: NSButton!
    @IBOutlet weak var tableViewButton: NSButton!
    
    @IBOutlet weak var refreshButton: NSButton!
    @IBOutlet weak var searchField: NSSearchField!
    @IBOutlet weak var createFolderButton: NSButton!
    var rootNodeName = NSLocalizedString("STRING_ROOT", comment: "")
    var rootNodeType = RepoNavItem.allFiles
    
    @IBOutlet weak var NXPopUpButton: NSPopUpButton!
    
    @IBOutlet weak var NXMenu: NSMenu!
    
    @IBOutlet weak var NXSharedSegment: NSSegmentedControl!
    
    weak var barDelegate: NXFileOperationBarDelegate? = nil
    
    private var curViewMode: NXFileOperationType? = nil

    let viewedHistory = PreviousViewed()
    var isViewHistory = false
    var isSupportPreviousView = true {
        didSet {
            changeViewedBtnDisplay()
        }
    }
    
    var pathNodes = [NXProjectFolder]()
    
    @IBOutlet weak var backBtn: NSButton!
    @IBOutlet weak var forwardBtn: NSButton!
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        
        // Drawing code here.
        changeViewedBtnDisplay()
    }
    
    func doWork(viewMode: NXFileOperationType){
        if viewMode == .tableView{
            viewAsTable()
        }else if viewMode == .gridView{
            viewAsGrid()
        }else{
            return
        }
        NXPopUpButton.isHidden = true
        
        self.hiddenRefreshButton(isHidden: false)
    }
    
    func showNode(node: NXFileBase?){
        let url = composePathURL(with: node?.fullPath)
        pathControl.url = url
        
        viewedHistoryChanged(with: node)
        
        // Special case
        // For project has no cache and no viewed history
        if node == nil {
            pathNodes.removeAll()
        } else if let projectFolder = node as? NXProjectFolder {
            pathNodes.append(projectFolder)
        }
        
    }
    
    func enableUploadButton(enable: Bool){
        uploadFileButton.isEnabled = enable
    }
    
    func enableDownloadButton(enable: Bool){
        downloadFileButton.isEnabled = enable
    }
    
    func enableCreateFolderButton(enable: Bool){
        createFolderButton.isEnabled = enable
    }
    
    func hiddenUploadButton(isHidden: Bool){
        uploadFileButton.isHidden = isHidden
    }
    
    func hiddenCreateFolderButton(isHidden: Bool){
        createFolderButton.isHidden = isHidden
    }
    
    func hiddenDownloadButton(isHidden: Bool){
        downloadFileButton.isHidden = isHidden
    }
    
    
    func hiddenSelectMenuButton(isHidden: Bool){
        NXPopUpButton.isHidden = isHidden
    }
    
    func hiddenRefreshButton(isHidden: Bool){
        refreshButton.isHidden = isHidden
    }

    func focusSearchField() {
        searchField.selectText(self)
        searchField.currentEditor()?.selectedRange = NSMakeRange(0, searchField.stringValue.count)
    }
    
    func hiddenSharedSegment(isHidden: Bool) {
        self.NXSharedSegment.isHidden = isHidden
    }
    
    func resetSharedSegment() {
        self.NXSharedSegment.selectedSegment = 1
    }
    
    func searchFilesOnly(filesOnly: Bool) {
        DispatchQueue.main.async {
            if filesOnly {
                self.searchField.placeholderString = "Search for files"
                self.searchField.needsLayout = true
            }
            else {
                self.searchField.placeholderString = "Search for files/folders"
                self.searchField.needsLayout = true
            }
        }
    }
    
    private func composePathURL(with folderPath: String?) -> URL {
        var absolutePath = "/" + rootNodeName
        if let folderPath = folderPath {
            absolutePath += folderPath
        }
        
        if #available(OSX 10.12, *) {
            return URL(string: absolutePath.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)!
        }else{
            //return URL(fileURLWithPath: absolutePath.addingPercentEncoding(withAllowedCharacters: NSCharacterSet.urlQueryAllowed)!)
            return URL(fileURLWithPath: absolutePath)
        }
    }
    
    private func removeRootNodeName(from path: String) -> String {
        var result = path
        let rootPath = "/" + rootNodeName
        if path.hasPrefix(rootPath) {
            result = String(path[path.index(path.startIndex, offsetBy: rootPath.count)...])
        }
        
        return result
    }
    
    @IBAction func onClickSearchField(_ sender: Any) {
        
        let searchString = self.searchField.stringValue
        if searchString.isEmpty{
            barDelegate?.fileOperationBarDelegate(type: .search, userData:"")
        }
        else
        {
            barDelegate?.fileOperationBarDelegate(type: .search, userData: searchString)
        }
    }
    
    @IBAction func gridViewClicked(_ sender: Any) {
        viewAsGrid()
    }
    
    @IBAction func tableViewClicked(_ sender: Any) {
        viewAsTable()
    }

    func seeViewedBack() {
        isViewHistory = true
        barDelegate?.fileOperationBarDelegate(type: .seeViewedBack, userData: nil)
        isViewHistory = false
    }
    @IBAction func seeViewedBack(_ sender: Any) {
        seeViewedBack()
    }
    func seeViewedForward() {
        isViewHistory = true
        barDelegate?.fileOperationBarDelegate(type: .seeViewedForward, userData: nil)
        isViewHistory = false
    }
    @IBAction func seeViewedForward(_ sender: Any) {
        seeViewedForward()
    }
    
    @IBAction func refreshClicked(_ sender: Any) {
        barDelegate?.fileOperationBarDelegate(type: .refreshClicked, userData: nil)
    }
    
    @IBAction func pathControlClicked(_ sender: Any) {
        
        if let clickedPath = pathControl.clickedPathComponentCell()?.url?.path,
            clickedPath != pathControl.url?.path {
            
            var fullPath = removeRootNodeName(from: clickedPath)
            // folder
            if fullPath.isEmpty == true ||
                fullPath[fullPath.index(before: fullPath.endIndex)] != "/" {
                fullPath.append("/")
            }
            
            // Special case
            // For project has no cache and no viewed history
            if !pathNodes.isEmpty {
                let nodeIndex = fullPath.components(separatedBy: "/").count - 3
                let projectFolder: NXProjectFolder? = (nodeIndex < 0) ? nil: pathNodes[nodeIndex]
                let removeCount = pathNodes.count - nodeIndex - 1
                for _ in 0..<removeCount {
                    pathNodes.removeLast()
                }
                
                barDelegate?.fileOperationBarDelegate(type: .pathNodeClicked, userData: projectFolder)
                return
            }
            
            
            barDelegate?.fileOperationBarDelegate(type: .pathNodeClicked, userData: fullPath)
        }
        
    }
    
    @IBAction func uploadFileClicked(_ sender: Any) {
        barDelegate?.fileOperationBarDelegate(type: .uploadFile, userData: nil)
    }
    
    @IBAction func downloadFileClicked(_ sender: Any) {
        barDelegate?.fileOperationBarDelegate(type: .downloadFile, userData: nil)
    }
    
    @IBAction func createFolderButtonClicked(_ sender: Any) {
          barDelegate?.fileOperationBarDelegate(type: .createFolder, userData: nil)
    }
    
    @IBAction func onClickPopUpButton(_ sender: Any) {
        
        let currentSelectedMenuTittle:String = (NXPopUpButton.selectedItem?.title)!
        
        barDelegate?.fileOperationBarDelegate(type: .selectMenuItem, userData: currentSelectedMenuTittle)
    }
    
    private func viewAsTable()
    {
        if curViewMode == .tableView{
            return
        }
        
        tableViewButton.image = NSImage(named:  "tableicon-sel")
        gridViewButton.image = NSImage(named:  "gridicon")
        
        curViewMode = .tableView
        barDelegate?.fileOperationBarDelegate(type: curViewMode!, userData: nil)
    }
    
    private func viewAsGrid(){
        if curViewMode == .gridView{
            return
        }
        
        tableViewButton.image = NSImage(named:  "tableicon")
        gridViewButton.image = NSImage(named:  "gridicon-sel")
        
        curViewMode = .gridView
        barDelegate?.fileOperationBarDelegate(type: curViewMode!, userData: nil)
    }
    
    func changeViewedBtnDisplay() {
        
        if !isSupportPreviousView {
            backBtn.isHidden = true
            forwardBtn.isHidden = true
            return
        }
        
        if viewedHistory.canMoveBack() {
            backBtn.image = NSImage(named:  "back")
            backBtn.isEnabled = true
        } else {
            backBtn.isEnabled = false
        }
        
        if viewedHistory.canMoveForward() {
            var img = NSImage(named:  "back")
            img = img?.imageRotatedByDegreess(degrees: 180)
            forwardBtn.image = img
            forwardBtn.isEnabled = true
        } else {
            var img = NSImage(named: "back")
            img = img?.imageRotatedByDegreess(degrees: 180)
            forwardBtn.image = img
            forwardBtn.isEnabled = false
        }
        NXMainMenuHelper.shared.enablePrevious(enable: backBtn.isEnabled)
        NXMainMenuHelper.shared.enableNext(enable: forwardBtn.isEnabled)
    }
    
    private func viewedHistoryChanged(with node: NXFileBase?) {
        if !isSupportPreviousView {
            return
        }
        
        if !isViewHistory {
            viewedHistory.append(with: (rootNodeType ,rootNodeName, node?.fullServicePath))
        }
        
        changeViewedBtnDisplay()
    }
    
    @IBAction func changeSharedSegmentValue(_ sender: NSSegmentedControl) {
        
        let isSharedWithMe = (NXSharedSegment.selectedSegment == 1) ? true: false
        barDelegate?.fileOperationBarDelegate(type: .changeSharedSegmentValue, userData: isSharedWithMe)
    }
    
    func settingAllFileOperationBtnDisable() {
        uploadFileButton.isEnabled = false
        downloadFileButton.isEnabled = false
        refreshButton.isEnabled = false
        searchField.isEnabled = false
        createFolderButton.isEnabled = false
    }
    
    func settingFileOperationBtnStatus(with item: RepoNavItem) {
        switch item {
        case .myVault,
             .favoriteFiles,
             .deleted,
             .shared:
            downloadFileButton.isEnabled = false
            refreshButton.isEnabled = true
            searchField.isEnabled = true
        case .myDrive,
             .cloudDrive:
            createFolderButton.isEnabled = true
            downloadFileButton.isEnabled = false
            uploadFileButton.isEnabled = true
            refreshButton.isEnabled = true
            searchField.isEnabled = true
        case .allFiles:
            refreshButton.isEnabled = true
            searchField.isEnabled = true
        default:
            break
        }
    }
    
    func defaultFileOperationStatusInProject() {
        createFolderButton.isEnabled = true
        downloadFileButton.isEnabled = false
        uploadFileButton.isEnabled = true
        refreshButton.isEnabled = true
        searchField.isEnabled = true
    }
}

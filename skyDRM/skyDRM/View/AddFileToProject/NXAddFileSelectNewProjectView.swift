//
//  NXAddFileSelectNewProjectView.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/5/15.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

protocol NXAddFileSelectNewProjectViewDelegate: NSObjectProtocol {
    func selectProjectFinished(syncFile: NXSyncFile?, projectModel: NXProjectModel?, destinationString: String?)
}


class NXAddFileSelectNewProjectView: NSView {
    
    fileprivate struct Constant{
        static let standardInterval: CGFloat = 1
        static let collectionViewItemWidth: CGFloat = 480
        static let collectionViewTagsItemFixedHeight: CGFloat = 25
        static let collectionViewFileNameItemFixedHeight: CGFloat = 73
        static let collectionViewCaculateWidth: CGFloat = 480
        static let collectionViewExtraDistance: CGFloat = 10
        static let collectionViewFileNameItemExtraSpace: CGFloat = 40
    }

    @IBOutlet weak var outlineView: NXMyOutlineView!
    @IBOutlet weak var backView: NSView!
    @IBOutlet weak var destinationLab: NSTextField!
    @IBOutlet weak var nextBtn: NSButton!
    @IBOutlet weak var cancelBtn: NSButton!
    
    @IBOutlet weak var collectionView: NSCollectionView!
    
    var collectionViewDataSource = [String]()
    
    weak var delegate: NXAddFileSelectNewProjectViewDelegate?
    var destinationBlock: SelectDestiBlock?
    var destinationStr: String?
    var fileNameDisplay: String?
    var targetPathArr = [String]()
    var filePath: String? {
        didSet {
            if filePath != nil {
               // self.fileNameLab.stringValue = (filePath! as NSString).lastPathComponent
                fileNameDisplay = (filePath! as NSString).lastPathComponent
                collectionView.reloadData()
            }
        }
    }
    var tags: [String: [String]]? {
        didSet {
            if tags != nil && tags?.count != 0 {
                collectionViewDataSource.removeAll()
                let tagDisplay  =  getTagsDisplayString(tags: tags!)
                for str in tagDisplay{
                    collectionViewDataSource.append(str)
                }
                collectionView.reloadData()
            }
        }
    }
    var preFileModel: NXProjectFileModel? {
        didSet {
            if preFileModel != nil {
                self.preProjectId = preFileModel?.project?.id
                destinationStr = ""
               // self.fileNameLab.stringValue = preFileModel?.name ?? ""
                fileNameDisplay = preFileModel?.name ?? ""
                collectionView.reloadData()
                
                showTag()
            }
        }
    }
    
    private func getTagsString(tags: [String: [String]]) -> (String, [String]) {
        var tagStr = ""
        var keysArr = [String]()
        for dict in tags {
            keysArr.append(dict.key)
            tagStr.append(dict.key)
            let sum = dict.value.count
            for (index,str) in dict.value.enumerated() {
                if sum == 1 {
                    tagStr = tagStr + "(" + str + ")"
                }else {
                    if index == sum - 1 {
                        tagStr = tagStr + str + ")"
                    }else if index == 0 {
                        tagStr = tagStr + "(" + str + ","
                    }else{
                        tagStr = tagStr + str + ","
                    }
                }
            }
            tagStr = tagStr + " "
        }
        return (tagStr,keysArr)
    }
    
    private func getTagsDisplayString(tags: [String: [String]]) -> ([String]) {
        var tagStr = ""
        var keysArr = [String]()
        var resultArr = [String]()
        if tags.keys.count == 0 {
            return [""]
        }
        for dict in tags {
            keysArr.append(dict.key)
            tagStr.append(dict.key)
            let sum = dict.value.count
            for (index,str) in dict.value.enumerated() {
                if sum == 1 {
                    tagStr = tagStr + ":" + "(" + str + ")"
                }else {
                    if index == sum - 1 {
                        tagStr = tagStr + str + ")"
                    }else if index == 0 {
                        tagStr = tagStr + ":" + "(" + str + ","
                    }else{
                        tagStr = tagStr + str + ","
                    }
                }
            }
            resultArr.append(tagStr)
            tagStr = ""
        }
        return resultArr
    }
    
    var projectModel: NXProjectModel? {
        didSet {
            if projectModel != nil {
                destinationStr = (projectModel?.name)! + "/"
                destinationLab.stringValue = destinationStr!
                  self.changeNextButtonState()
            }
        }
    }
    
    var syncFile: NXSyncFile? {
        didSet {
            if syncFile != nil {
                destinationStr = NXCommonUtils.getDestinationString(file: syncFile!.file)
                
                destinationLab.stringValue = destinationStr ?? ""
               self.changeNextButtonState()
            }
        }
    }
    
    fileprivate func changeNextButtonState(){
         nextBtn.isEnabled = true
        
        let titleAttr = NSMutableAttributedString(attributedString: nextBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, nextBtn.title.count))
        nextBtn.attributedTitle = titleAttr
    }

    
    fileprivate var preProjectId: Int? = 0
    var rootModel: NXProjectRoot? {
        didSet {
            if rootModel != nil {
                self.outlineView.reloadData()
                self.outlineView.expandItem(rootModel, expandChildren: false)
                
                if projectModel != nil {
                    for project in rootModel?.projects ?? [] {
                        if project.id == projectModel?.id {
                            let row = self.outlineView.row(forItem: project)
                            self.outlineView.selectRowIndexes(IndexSet([row]), byExtendingSelection: true)
                            self.outlineView.scrollRowToVisible(row)
                            if project.folders.count != 0 {
                                self.outlineView.expandItem(project, expandChildren: false)
                            }
                            break
                        }
                    }
                }else if syncFile != nil {
                    if let fileModel = syncFile?.file as? NXProjectFileModel {
                        // 获取所选文件的父集文件ID
                        getTargetPathArr(fileModel: fileModel)
                        for project in rootModel?.projects ?? [] {
                            if project.id == fileModel.project?.id {
                                self.outlineView.expandItem(project, expandChildren: false)
                                //依次打开所选文件所在目录
                                openSelectFile(syncFiles: project.folders)
                                break
                            }
                        }
                    }
                    
                }
            }
            
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        if #available(OSX 10.13, *) {
            registerForDraggedTypes([NSPasteboard.PasteboardType.URL])
        } else {
            registerForDraggedTypes([NSPasteboard.PasteboardType(kUTTypeURL as String)])
        }

    }
    
    override func draggingEntered(_ sender: NSDraggingInfo) -> NSDragOperation {
        return .copy
    }
    
    override func prepareForDragOperation(_ sender: NSDraggingInfo) -> Bool {
        return true
    }
    
    override func performDragOperation(_ sender: NSDraggingInfo) -> Bool {
        let pasteBoard = sender.draggingPasteboard
        if let urls = pasteBoard.readObjects(forClasses: [NSURL.self]) as? [URL], urls.count > 0 {
            do {
                if urls.count > 0 {
                    let attr : NSDictionary? = try FileManager.default.attributesOfItem(atPath: urls[0].path) as NSDictionary?
                    if attr?.fileSize() == 0 {
                        NSAlert.showAlert(withMessage: NSLocalizedString("FILE_OPERATION_SHARE_PROTECT_EMPTY_FILE", comment: ""), informativeText: "", dismissClosure: { (type) in
                        })
                        return true
                    }
                }
                if FileManager.default.contents(atPath: urls.first!.path) != nil {
                    YMLog("文件可以打开")
                    let openPanel = NSOpenPanel()
                    openPanel.canChooseFiles = false
                    openPanel.canChooseDirectories = true
                    openPanel.canCreateDirectories = false
                    openPanel.worksWhenModal = true
                    openPanel.allowsMultipleSelection = false
                    openPanel.message = "This application needs to access the directory to do the corresponding operation to protect the file, please directly click the allow button"   //本应用需要访问该目录，才能做保护文件的相应操作 请直接点击允许按钮
                    openPanel.prompt = "Allow"
                    openPanel.directoryURL = URL.init(string: NSHomeDirectory())
                    openPanel.beginSheetModal(for: self.window!) { (result) in
                        if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                            YMLog(openPanel.urls)
                            let path = openPanel.urls.first?.appendingPathComponent(String.init(format: "%@", "eBook.pdf"), isDirectory: true).path
                            do {
                                try  FileManager.default.copyItem(atPath: urls.first!.path, toPath: path!)
                                
                            } catch {

                            }
                            let url = openPanel.urls.first
                            
                            let array = FileManager.default.enumerator(at: url!, includingPropertiesForKeys: nil)
                            _ = FileManager.default.subpaths(atPath: url!.path)
                            _ = try! FileManager.default.contentsOfDirectory(atPath: url!.path)
                            for _ in array! {
                                
                            }
                            
                        }else {
                            
                        }
                    }
                }
            } catch {
    
            }
        }
        return false
            
    }
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        self.wantsLayer = true
        self.layer?.backgroundColor = RGB(r: 236, g: 236, b: 236).cgColor
        self.backView.wantsLayer = true
        self.backView.layer?.borderColor = RGB(r: 197, g: 197, b: 197).cgColor
        self.backView.layer?.borderWidth = 1
        
        
       // lineView.wantsLayer = true
       // lineView.layer?.backgroundColor = RGB(r: 236, g: 236, b: 236).cgColor
        
        nextBtn.wantsLayer = true
        nextBtn.layer?.cornerRadius = 5
        nextBtn.layer?.backgroundColor = NSColor.white.cgColor
        nextBtn.isEnabled = false
        
        let startColor = NSColor.init(colorWithHex: NXConstant.NXColor.linear.0)!
        let endColor = NSColor.init(colorWithHex: NXConstant.NXColor.linear.1)!
        let gradientLayer = NXCommonUtils.createLinearGradientLayer(frame: nextBtn.bounds, start: startColor, end: endColor)
        nextBtn.layer?.addSublayer(gradientLayer)
        
        let titleAttr = NSMutableAttributedString(attributedString: nextBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, nextBtn.title.count))
        nextBtn.attributedTitle = titleAttr
        
        cancelBtn.wantsLayer = true
        cancelBtn.layer?.cornerRadius = 5
        cancelBtn.layer?.backgroundColor = NSColor.white.cgColor
        
        collectionView.wantsLayer = true
        collectionView.layer?.backgroundColor = NSColor.white.cgColor
        
        collectionView.register(NXAddFileSelectNewProjectViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier.init("NXAddFileSelectNewProjectViewItemIdentifier"))
        collectionView.register(NXTagsDisplayViewItem.self, forItemWithIdentifier: NSUserInterfaceItemIdentifier.init("NXTagsDisplayViewItemIdentifier"))
    
        configureCollectionView()
    
}

    fileprivate func configureCollectionView() {
        let flowLayout = NSCollectionViewFlowLayout()
        flowLayout.itemSize = NSSize(width: 503, height: 30)
        flowLayout.minimumInteritemSpacing = 1
        flowLayout.minimumLineSpacing = 1
        collectionView.collectionViewLayout = flowLayout
    }
}

extension NXAddFileSelectNewProjectView {
    
    @IBAction func nextAction(_ sender: Any) {
        guard destinationStr != "" else {
            let message = "请选择一个project"//"PROJECT_FILES_PROTECT_MANDATORY_NO".localized
            NSAlert.showAlert(withMessage: message)
            return
        }
        self.delegate?.selectProjectFinished(syncFile: self.syncFile, projectModel: self.projectModel, destinationString: self.destinationStr)
    }
    
    @IBAction func onCancel(_ sender: Any) {
        guard let vc = self.window?.contentViewController else {
            return
        }
        vc.presentingViewController?.dismiss(vc)
    }
    
    func openSelectFile(syncFiles: [NXSyncFile]) {
        if targetPathArr.count == 0 {
            return
        }
        
        for syncFile in syncFiles {
            if let fileModel = syncFile.file as? NXProjectFileModel, self.isContainTargetFilePath(filePath: fileModel.fullServicePath) {
                if fileModel.subFolders.count != 0 {
                    self.outlineView.expandItem(syncFile, expandChildren: false)
                }
                targetPathArr.remove(at: 0)
                if targetPathArr.count == 0 {
                    let row = self.outlineView.row(forItem: syncFile)
                    self.outlineView.selectRowIndexes(IndexSet([row]), byExtendingSelection: true)
                    self.outlineView.scrollRowToVisible(row)
                }
                openSelectFile(syncFiles: fileModel.subFolders)
                break
            }
        }
    }
    
    func getTargetPathArr(fileModel: NXProjectFileModel) {
        let pathArray = fileModel.fullServicePath.components(separatedBy: "/")
        for item in pathArray {
            targetPathArr.append(item)
        }
        targetPathArr = targetPathArr.filter{
            $0 != ""
        }
    }
    
    func isContainTargetFilePath(filePath:String) -> Bool {
        if let fileModel = syncFile!.file as? NXProjectFileModel {
            if fileModel.fullServicePath.hasPrefix(filePath){
                return true
            }else{
                return false
            }
        }
        return false
    }
    
    private func showTag() {
        if (preFileModel?.tags != nil && preFileModel?.tags?.count != 0) {
            collectionViewDataSource.removeAll()
            let tagDisplay  =  getTagsDisplayString(tags: (preFileModel?.tags)!)
            for str in tagDisplay{
                collectionViewDataSource.append(str)
            }
            collectionView.reloadData()
        }
    }
}

extension NXAddFileSelectNewProjectView: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let rootModel = item as? NXProjectRoot {
            return rootModel.projects.count
        }else if let project = item as? NXProjectModel {
            return project.folders.count
        }else if let folder = item as? NXSyncFile {
            if let fileModel = folder.file as? NXProjectFileModel {
                return fileModel.subFolders.count
            }
            return 0
        }
        return 1
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil  {
            return rootModel as Any
        }else if let rootModel = item as? NXProjectRoot {
            return rootModel.projects[index]
        }else if let project = item as? NXProjectModel {
            return project.folders[index]
        }else if let folder = item as? NXSyncFile {
            if let fileModel = folder.file as? NXProjectFileModel {
                return fileModel.subFolders[index]
            }
            return "bad item"
        }
        return "bad item"
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if let rootModel = item as? NXProjectRoot {
            return rootModel.projects.count > 0
        }else if let project = item as? NXProjectModel {
            if project.id == preProjectId {
                return false
            }
            return project.folders.count > 0
        }else if let folder = item as? NXSyncFile {
            if let fileModel = folder.file as? NXProjectFileModel {
                return fileModel.subFolders.count > 0
            }
            return false
        }
        return true
    }
}

extension NXAddFileSelectNewProjectView: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        guard let rowView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "AddFileCustomRowView"), owner: self) as? NXCustomRowView else {
            let rowView = NXCustomRowView()
            rowView.identifier = NSUserInterfaceItemIdentifier(rawValue: "AddFileCustomRowView")
            return rowView
        }
        return rowView
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "destinationCellView"), owner: self) as? NSTableCellView
        cell?.textField?.textColor = NSColor.color(withHexColor: "#353535")
        if item is NXProjectRoot {
            cell?.imageView?.image = NSImage.init(named:  "Project")
            cell?.textField?.stringValue = "Project"
        }else if let project = item as? NXProjectModel {
            if project.id == preProjectId {
                cell?.textField?.textColor = NSColor.color(withHexColor: "#8F8F8F")
            }
            cell?.imageView?.image = NSImage.init(named: (project.ownedByMe == true ?  "User" :  "Nouser"))
            cell?.textField?.stringValue = project.name 
        }else if let folder = item as? NXSyncFile {
            if let fileModel = folder.file as? NXProjectFileModel {
                cell?.imageView?.image = NSImage(named: NSImage.folderName);         cell?.textField?.stringValue = fileModel.name
            }
        }
        return cell
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        if let project = item as? NXProjectModel {
            if project.id == preProjectId {
                return false
            }
            projectModel = project
            syncFile     = nil
        } else if let folder = item as? NXSyncFile {
            if let file = folder.file as? NXProjectFileModel, file.project?.id == preProjectId {
                return false
            }
            syncFile     = folder
            projectModel = nil
        }
        return true
    }
    
}

extension NXAddFileSelectNewProjectView: NSCollectionViewDataSource{
    func numberOfSections(in collectionView: NSCollectionView) -> Int {
        return 2
    }
    
    func collectionView(_ collectionView: NSCollectionView, numberOfItemsInSection section: Int) -> Int {
        if section == 0 {
            return 1
        }else{
            return collectionViewDataSource.count
        }
    }
    
    func collectionView(_ collectionView: NSCollectionView, itemForRepresentedObjectAt indexPath: IndexPath) -> NSCollectionViewItem {
        if indexPath.section == 0 {
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NXAddFileSelectNewProjectViewItemIdentifier"), for: indexPath)
            guard let viewItem = item as? NXAddFileSelectNewProjectViewItem else {
                return item
            }
            viewItem.setFileName(fileName: fileNameDisplay)
           
            return viewItem
        }else {
            
            let item = collectionView.makeItem(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "NXTagsDisplayViewItemIdentifier"), for: indexPath)
            guard let viewItem = item as? NXTagsDisplayViewItem else {
                return item
            }
            let rightsDisplay = collectionViewDataSource[indexPath.item]
            viewItem.setRightsLabelDisplay(rightsTagDisplay:rightsDisplay)
            
            return viewItem
        }
    }
}

extension NXAddFileSelectNewProjectView : NSCollectionViewDelegateFlowLayout {
    func collectionView(_ collectionView: NSCollectionView, layout collectionViewLayout: NSCollectionViewLayout, sizeForItemAt indexPath: IndexPath) -> NSSize {
        
        if indexPath.section == 0 {
            if let fileName = fileNameDisplay{
                let size = getStringSizeWithFont(string: fileName, font: NSFont.systemFont(ofSize: 14), maxSize: NSSize(width: Constant.collectionViewCaculateWidth, height: CGFloat.greatestFiniteMagnitude))
                if (size.height + Constant.collectionViewFileNameItemExtraSpace) < Constant.collectionViewFileNameItemFixedHeight{
                     return NSSize(width: Constant.collectionViewItemWidth,height: Constant.collectionViewFileNameItemFixedHeight)
                }else{
                     return NSSize(width: Constant.collectionViewItemWidth,height: size.height + Constant.collectionViewExtraDistance + Constant.collectionViewFileNameItemExtraSpace)
                }
            }else{
                return NSSize(width: Constant.collectionViewItemWidth,height: Constant.collectionViewFileNameItemFixedHeight)
            }
        }else{
            
            let tagDisplay = collectionViewDataSource[indexPath.item]
            if tagDisplay.count > 0{
               let size = getStringSizeWithFont(string: tagDisplay, font: NSFont.systemFont(ofSize: 14), maxSize: NSSize(width:Constant.collectionViewCaculateWidth, height: CGFloat.greatestFiniteMagnitude))
              
                if size.height < Constant.collectionViewTagsItemFixedHeight {
                     return  NSSize(width: Constant.collectionViewItemWidth,height: Constant.collectionViewTagsItemFixedHeight)
                }else{
                     return  NSSize(width: Constant.collectionViewItemWidth,height: size.height + Constant.collectionViewExtraDistance)
                }
            }else{
                return  NSSize(width: Constant.collectionViewItemWidth,height: Constant.collectionViewTagsItemFixedHeight)
            }
        }
    }
}



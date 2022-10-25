//
//  NXSiderBarViewController.swift
//  skyDRM
//
//  Created by William (Weiyan) Zhao on 2018/12/18.
//  Modified by Paul.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa
import SDML

enum selectecType  {
    case myVault
    case sharedWithMe
    case allOffline
    case outBox
    case project
    case projectFolder
    case projectFile
    case workspace
}

protocol NXSiderBarViewControllerDelegate: class {
    func operationClick(type: selectecType, value: Any?)
}

class NXSiderBarViewController: NSViewController {
    
    class CloudDrive {
        var type: NXDriverType
        var files: [NXFileBase]
        
        init(type: NXDriverType, files: [NXFileBase]) {
            self.type = type
            self.files = files
        }
    }
    
    @IBOutlet weak var allOfflineView: NSView!
    @IBOutlet weak var outBoxView: NSView!
    @IBOutlet weak var projectOutlineView: NSOutlineView!
    @IBOutlet weak var allOfflineFilesBtn: NSButton!
    @IBOutlet weak var outBoxBtn: NSButton!
    
    var preView = NSView()
    
    var projectList = [Any]()
    
    weak var delegate:NXSiderBarViewControllerDelegate?
    override func viewDidLoad() {
        super.viewDidLoad()
        initView()
        
        initData()
    }
    
    
    
    fileprivate func initView() {

        allOfflineFilesBtn.appearance = NSAppearance(named: .aqua)
        outBoxBtn.appearance = NSAppearance(named: .aqua)
        location()
        outBoxView.wantsLayer = true
        preView = outBoxView
        projectOutlineView.delegate = self
        projectOutlineView.dataSource = self
        projectOutlineView.needsLayout = true
        projectOutlineView.autoresizesOutlineColumn = false
        preView.layer?.backgroundColor = NSColor(colorWithHex: "#C0BFC1")?.cgColor
        let viewArray = [outBoxView,allOfflineView]
        for view  in viewArray {
            let Tap = NSClickGestureRecognizer(target: self, action: #selector(changeBackgroundColor(_:)))
            Tap.buttonMask = 0x1
            Tap.numberOfClicksRequired = 1
            Tap.delaysPrimaryMouseButtonEvents = true
            view?.addGestureRecognizer(Tap)
        }
        setBtnImageAndTitleSpace(btn: allOfflineFilesBtn)
        setBtnImageAndTitleSpace(btn: outBoxBtn)
    }
    
    
    fileprivate func location() {
        allOfflineFilesBtn.title = "SIDERBAR_NAME_ALLOFFLINEFILES".localized
        outBoxBtn.title = "SIDERBAR_NAME_OUTBOX".localized
    }
    
    // MARK: -Change the viewbackground color and skip the file lsit view
    @objc private func changeBackgroundColor(_ gesture: NSGestureRecognizer?) {
        gesture?.view?.wantsLayer = true
        preView.layer?.backgroundColor = NSColor(colorWithHex: "#ECECEC")?.cgColor
        gesture?.view?.layer?.backgroundColor = NSColor(colorWithHex: "#C0BFC1")?.cgColor
        preView = gesture?.view ?? outBoxView
        var type: selectecType
        switch  gesture?.view {
            case allOfflineView:
                type = .allOffline
            case outBoxView:
                type = .outBox
            default:
                type = .outBox
        }
        projectOutlineView.deselectRow(projectOutlineView.selectedRow)
        delegate?.operationClick(type: type, value: nil)
    }

    private func setBtnImageAndTitleSpace(btn: NSButton) {
        let attributedStr = NSMutableAttributedString.init(attributedString: btn.attributedTitle)
        let style = NSMutableParagraphStyle.init()
        style.firstLineHeadIndent = 6
        attributedStr.addAttribute(NSAttributedString.Key.paragraphStyle, value: style, range: NSRange.init(location: 0, length: attributedStr.length))
        btn.attributedTitle = attributedStr
    }
    
    private func initData() {
        var list = [Any]()
        if NXClientUser.shared.user?.isPersonal == false && AppConfig.isHiddenWorkspace == false {
            let workspace = CloudDrive(type: .workspace, files: NXMemoryDrive.sharedInstance.getWorkspace())
            list.append(workspace)
        }
        
        let myVault = CloudDrive(type: .myVault, files: [])
        list.append(myVault)
        let shareWithMe = CloudDrive(type: .shareWithMe, files: [])
        list.append(shareWithMe)
        let allProject = NXMemoryDrive.sharedInstance.getProject()
        list.append(allProject)
        
        self.projectList = list
        self.projectOutlineView.reloadData()
        
        self.projectOutlineView.expandItem(allProject)
    }
}

// MARK: Public methods.
extension NXSiderBarViewController {
    // Select item under select item.
    func select(item: Any) {
        let selectRow = projectOutlineView.selectedRow
        let project = projectOutlineView.item(atRow: selectRow)
        if !projectOutlineView.isItemExpanded(project) {
            projectOutlineView.expandItem(project)
        }
        let row = projectOutlineView.row(forItem: item)
        projectOutlineView.centreRow(row: row, animated: true)
        projectOutlineView.selectRowIndexes([row], byExtendingSelection: false)
    }
    
    func refresh() {
        if let selected = getSelected() {
            if selected.type == .project {
                var project: NXProjectModel?
                if let projectModel = selected.value as? NXProjectModel {
                    project = projectModel
                } else if let syncFile = selected.value as? NXSyncFile, let projectFile = syncFile.file as? NXProjectFileModel, let projectModel = projectFile.project {
                    project = projectModel
                }

                refresh(type: .project, value: project)

            } else {
                refresh(type: selected.type)
            }
        }
    }
    
}

// MARK: - Outline Delegate.

extension NXSiderBarViewController:NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        guard let rowView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CustomRowView"), owner: nil) as? NXCustomRowView else {
            let rowView = NXCustomRowView()
            rowView.identifier = NSUserInterfaceItemIdentifier(rawValue: "CustomRowView")
            return rowView
        }
        return rowView
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        var cell:NSTableCellView?
        if let cloudDrive = item as? CloudDrive {
            if cloudDrive.type == .workspace {
                cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SharedWithMeCell"), owner: self) as? NSTableCellView
                cell?.imageView?.image = NSImage(named: "workspace")
                cell?.textField?.stringValue = "SIDERBAR_NAME_WORKSPACE".localized
                cell?.textField?.textColor = NSColor.color(withHexColor: "#353535")
            } else if cloudDrive.type == .myVault {
                cell = outlineView.makeView(withIdentifier:NSUserInterfaceItemIdentifier(rawValue: "MyVaultCell") , owner: self) as? NSTableCellView
                cell?.textField?.stringValue = "SIDERBAR_NAME_MYVAULT".localized
                cell?.textField?.textColor = NSColor.color(withHexColor: "#353535")
            } else if cloudDrive.type == .shareWithMe {
                cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "SharedWithMeCell"), owner: self) as? NSTableCellView
                cell?.textField?.stringValue = "SIDERBAR_NAME_SHAREDWITHME".localized
                cell?.textField?.textColor = NSColor.color(withHexColor: "#353535")
            }
        } else if item is NXProjectRoot {
            cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "HeaderCell"), owner: self) as? NSTableCellView
            cell?.textField?.stringValue = "SIDERBAR_NAME_PROJECT".localized
            cell?.textField?.textColor = NSColor.color(withHexColor: "#353535")
        } else if item is NXProjectModel {
            cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as? NSTableCellView
             cell?.textField?.textColor = NSColor.color(withHexColor: "#353535")
            cell?.textField?.stringValue = (item as? NXProjectModel)?.name ?? ""
            if (item as? NXProjectModel)?.ownedByMe == true {
                cell?.imageView?.image = NSImage(named: "User")
            } else {
                cell?.imageView?.image = NSImage(named: "Nouser")
            }
        } else if item is NXSyncFile {
            cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as? NSTableCellView
            cell?.textField?.textColor = NSColor.color(withHexColor: "#353535")
            cell?.textField?.stringValue = (item as? NXSyncFile)?.file.name ?? ""
            cell?.imageView?.image = NSImage(named: NSImage.folderName)
        } else if let file = item as? NXFileBase {
            cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "DataCell"), owner: self) as? NSTableCellView
            cell?.textField?.textColor = NSColor.color(withHexColor: "#353535")
            cell?.textField?.stringValue = file.name
            cell?.imageView?.image = NSImage(named: NSImage.folderName)
        }
        
        return cell
    }
    
    func outlineView(_ outlineView: NSOutlineView, heightOfRowByItem item: Any) -> CGFloat {
        if item is CloudDrive || item is NXProjectRoot {
            return 37
        }
        
        return 20
    }
    
    func outlineViewSelectionDidChange(_ notification: Notification) {
        let item = projectOutlineView.item(atRow: projectOutlineView.selectedRow)
        if let cloudDrive = item as? CloudDrive {
            preView.layer?.backgroundColor = NSColor(colorWithHex: "#ECECEC")?.cgColor
            if cloudDrive.type == .workspace {
                delegate?.operationClick(type: .workspace, value: nil)
            } else if cloudDrive.type == .myVault {
                delegate?.operationClick(type: .myVault, value: nil)
            } else if cloudDrive.type == .shareWithMe {
                delegate?.operationClick(type: .sharedWithMe, value: nil)
            }
        } else if item is NXProjectRoot {
            preView.layer?.backgroundColor = NSColor(colorWithHex: "#ECECEC")?.cgColor
            delegate?.operationClick(type:.project, value: item as? NXProjectRoot)
        } else if item is NXProjectModel {
             preView.layer?.backgroundColor = NSColor(colorWithHex: "#ECECEC")?.cgColor
             delegate?.operationClick(type: .projectFolder, value: item as? NXProjectModel)
        } else if item is NXSyncFile {
             preView.layer?.backgroundColor = NSColor(colorWithHex: "#ECECEC")?.cgColor
             delegate?.operationClick(type: .projectFile, value: item as? NXSyncFile)
        } else if item is NXWorkspaceBaseFile {
            preView.layer?.backgroundColor = NSColor(colorWithHex: "#ECECEC")?.cgColor
            delegate?.operationClick(type: .workspace, value: item)
        }
    }
}

extension NXSiderBarViewController:NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if let cloudDrive = item as? CloudDrive {
            let folders = cloudDrive.files.filter() { $0.isFolder }
            return folders.count
        } else if let item = item as? NXProjectRoot {
            return item.projects.count
        } else if let newietm = item as? NXProjectModel {
            return newietm.folders.count
        } else if let otherItem = item as? NXSyncFile {
            guard  let oneItem = otherItem.file as? NXProjectFileModel else {
                return 0
            }
            return oneItem.subFolders.count
        } else if let file = item as? NXFileBase {
            if let children = file.children {
                let folders = children.filter() { $0.isFolder }
                return folders.count
            }
            
        }
        
        return projectList.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        
        if let cloudDrive = item as? CloudDrive {
            let folders = cloudDrive.files.filter() { $0.isFolder }
            if folders.count > 0 {
                return true
            }
        } else if let allProject = item as? NXProjectRoot {
            if allProject.projects.count > 0 {
                return true
            }
        } else if let project = item as? NXProjectModel {
            if project.folders.count > 0 {
                return true
            }
        } else if let syncFile = item as? NXSyncFile,
            let projectFolder = syncFile.file as? NXProjectFileModel {
            if projectFolder.subFolders.count > 0 {
                return true
            }
        } else if let file = item as? NXFileBase {
            if let children = file.children {
                let folders = children.filter() { $0.isFolder }
                if folders.count > 0 {
                    return true
                }
            }
        }
        
        return false
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if let cloudDrive = item as? CloudDrive {
            var folders = cloudDrive.files.filter() { $0.isFolder }
            folders.sort { $0.name.lowercased() < $1.name.lowercased() }
            return folders[index]
        } else if let item = item as? NXProjectRoot {
            return item.projects[index]
        } else if let item = item as? NXProjectModel {
            return item.folders[index]
        } else if let item = item as? NXSyncFile {
            if let newItem = item.file as? NXProjectFileModel {
                return newItem.subFolders[index]
            }
        } else if let file = item as? NXFileBase {
            var folders = file.children!.filter() { $0.isFolder }
            folders.sort { $0.name.lowercased() < $1.name.lowercased() }
            return folders[index]
        }
        
        return projectList[index]
    }
}
extension NXSiderBarViewController {
    
    private func refreshProject()  {
        self.projectOutlineView.reloadData()
        for item in projectList {
            if item is NXProjectRoot {
                let row = self.projectOutlineView.row(forItem: item)
                self.projectOutlineView.expandItem(row)
            }
        }
    }
    
    private func refreshWorkspace()  {
        var index = 0
        for (i, item) in projectList.enumerated() {
            if let cloudDrive = item as? CloudDrive,
                cloudDrive.type == .workspace {
                index = i
            }
        }
        let workspace = CloudDrive(type: .workspace, files: NXMemoryDrive.sharedInstance.getWorkspace())
        projectList[index] = workspace
        self.projectOutlineView.reloadData()
        for item in projectList {
            if item is NXProjectRoot {
                let row = self.projectOutlineView.row(forItem: item)
                self.projectOutlineView.expandItem(row)
            }
        }
    }
    
    private func getSelected() -> (type: NXDriverType, value: Any)? {
        let selectedRow = projectOutlineView.selectedRow
        if selectedRow == -1 {
            return nil
        }
        
        var result: (type: NXDriverType, value: Any)?
        let selectedItem = projectOutlineView.item(atRow: selectedRow)!
        if let cloudDrive = selectedItem as? CloudDrive {
            result = (type: cloudDrive.type, value: selectedItem)
        } else if selectedItem is NXProjectRoot {
            result = (type: .allProject, value: selectedItem)
        } else if selectedItem is NXProjectModel {
            result = (type: .project, value: selectedItem)
        } else if selectedItem is NXSyncFile {
            result = (type: .project, value: selectedItem)
        } else if selectedItem is NXWorkspaceBaseFile {
            result = (type: .workspace, value: selectedItem)
        }
        
        return result
    }
    
    private func refresh(type: NXDriverType, value: Any? = nil) {
        if type == .project {
            NotificationCenter.post(notification: .startRefresh, object: type)
            NXMemoryDrive.sharedInstance.refresh(type: type, project: value as! NXProjectModel) { (error) in
                NotificationCenter.post(notification: .stopRefresh, object: type)
                if error != nil {
                    return
                }
                
                self.updateUIAfterRefresh(type: type)
                
            }
            
        } else {
            NotificationCenter.post(notification: .startRefresh, object: type)
            NXMemoryDrive.sharedInstance.refresh(type: type) { (error) in
                NotificationCenter.post(notification: .stopRefresh, object: type)
                if error != nil {
                    return
                }
                
                self.updateUIAfterRefresh(type: type)
                
            }
        }
    }
    
    private func updateUIAfterRefresh(type: NXDriverType, value: Any? = nil) {
        let selected = getSelected()
        switch type {
        case .myVault:
            if type == selected?.type {
                NotificationCenter.post(notification: .refreshMyVault)
            }
        case .shareWithMe:
            if type == selected?.type {
                NotificationCenter.post(notification: .refreshShareWithMe)
            }
        case .allProject:
            // Reload data.
            initData()
            backSelectedAfterRefresh(selected: selected!)
            
        case .project:
            // Reload Data.
            initData()
            backSelectedAfterRefresh(selected: selected!)
            
        case .workspace:
            initData()
            backSelectedAfterRefresh(selected: selected!)
            
        default:
            break
        }
    }
    
    private func backSelectedAfterRefresh(selected: (type: NXDriverType, value: Any)) {
        if selected.type == .myVault {
            var index = 0
            for (i, item) in projectList.enumerated() {
                if let cloudDrive = item as? CloudDrive,
                    cloudDrive.type == .myVault {
                    index = i
                }
            }
            self.projectOutlineView.selectRowIndexes([index], byExtendingSelection: false)
        } else if selected.type == .shareWithMe {
            var index = 0
            for (i, item) in projectList.enumerated() {
                if let cloudDrive = item as? CloudDrive,
                    cloudDrive.type == .shareWithMe {
                    index = i
                }
            }
            self.projectOutlineView.selectRowIndexes([index], byExtendingSelection: false)
        } else if selected.type == .project {
            var index = 0
            for (i, item) in projectList.enumerated() {
                if item is NXProjectRoot {
                    index = i
                }
            }
            if let _ = selected.value as? NXProjectRoot {
                self.projectOutlineView.selectRowIndexes([index], byExtendingSelection: false)
            } else if let selectProject = selected.value as? NXProjectModel {
                var newProject: NXProjectModel?
                if let root = projectList[index] as? NXProjectRoot {
                    for project in root.projects {
                        if project.id == selectProject.id {
                            
                            newProject = project
                            break
                        }
                    }
                }
                
                if let updatedProject = newProject {
                    let row = self.projectOutlineView.row(forItem: updatedProject)
                    self.projectOutlineView.selectRowIndexes([row], byExtendingSelection: false)
                } else {
                    self.projectOutlineView.selectRowIndexes([index], byExtendingSelection: false)
                }
                
            } else if let syncFile = selected.value as? NXSyncFile, let selectProjectFile = syncFile.file as? NXProjectFileModel {
                var newProject: NXProjectModel?
                if let root = projectList[index] as? NXProjectRoot {
                    for project in root.projects {
                        if project.id == selectProjectFile.project?.id {
                            
                            newProject = project
                            break
                        }
                    }
                    
                }
                
                if newProject == nil {
                    self.projectOutlineView.selectRowIndexes([index], byExtendingSelection: false)
                    return
                }
                
                var result = [NXSyncFile]()
                let isFind = NXCommonUtils.searchProjectFile(fullServicePath: selectProjectFile.fullServicePath, in: newProject!, result: &result)
                if !isFind {
                    let row = self.projectOutlineView.row(forItem: newProject!)
                    self.projectOutlineView.selectRowIndexes([row], byExtendingSelection: false)
                } else {
                    if !self.projectOutlineView.isItemExpanded(newProject) {
                        self.projectOutlineView.expandItem(newProject)
                    }
                    
                    let last = result.popLast()
                    for file in result {
                        if !self.projectOutlineView.isItemExpanded(file) {
                            self.projectOutlineView.expandItem(file)
                        }
                    }
                    let row = self.projectOutlineView.row(forItem: last)
                    self.projectOutlineView.selectRowIndexes([row], byExtendingSelection: false)
                    
                }
            }
        } else if selected.type == .workspace {
            var index = 0
            for (i, item) in projectList.enumerated() {
                if let cloudDrive = item as? CloudDrive,
                    cloudDrive.type == .workspace {
                    index = i
                    break
                }
            }
            
            if selected.value is CloudDrive {
                self.projectOutlineView.selectRowIndexes([index], byExtendingSelection: false)
            } else if let file = selected.value as? NXWorkspaceBaseFile {
                var stack = [NXWorkspaceBaseFile]()
                if NXCommonUtils.searchWorkspaceFileStack(id: file.id, files: (projectList[index] as! CloudDrive).files as! [NXWorkspaceBaseFile], stack: &stack) {
                    let workspace = projectList[index]
                    if !self.projectOutlineView.isItemExpanded(workspace) {
                        self.projectOutlineView.expandItem(workspace)
                    }
                    let last = stack.popLast()
                    for file in stack {
                        if !self.projectOutlineView.isItemExpanded(file) {
                            self.projectOutlineView.expandItem(file)
                        }
                    }
                    let row = self.projectOutlineView.row(forItem: last)
                    self.projectOutlineView.selectRowIndexes([row], byExtendingSelection: false)
                }
                
            }
        }
    }
}





//
//  NXSelectDestinationView.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/3/27.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa



typealias SelectDestiBlock = (_ destination: String?) -> ()

enum SelectDestinationType {
    case workspace
    case myVault
    case project
    case folder
}

class NXSelectDestinationView: NSView {
    
    class MyVaultModel {
        let name: String = "MyVault"
    }
    
    class WorkspaceModel {
        let name: String = "Workspace"
        var files: [NXFileBase]
        
        init(files: [NXFileBase]) {
            self.files = files
        }
    }
    
    @IBOutlet weak var outlineView: NXMyOutlineView!
    var destinationBlock: SelectDestiBlock?
    var destinationStr: String?
    var type: SelectDestinationType?
    var targetPathArr = [String]()
    var  protectType: NXProtectType?
    var       rootModel: NXProjectRoot? {
        didSet {
            if rootModel != nil {
                
                // Show workspace or not.
                var showWorkspace = false
                if NXClientUser.shared.user?.isPersonal == false && AppConfig.isHiddenWorkspace == false {
                    let workspace = WorkspaceModel(files: NXMemoryDrive.sharedInstance.getWorkspace())
                    dataArr.append(workspace)
                    
                    showWorkspace = true
                }
                
                dataArr.append(MyVaultModel())
                dataArr.append(rootModel!)
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
                }else if syncFile != nil &&  protectType == .project {
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

                } else if let workspaceFolder = syncFile?.file as? NXWorkspaceBaseFile {
                    var workspace: WorkspaceModel?
                    for item in dataArr {
                        if let item = item as? WorkspaceModel {
                            workspace = item
                            break
                        }
                    }
                    
                    var stack = [NXWorkspaceBaseFile]()
                    if NXCommonUtils.searchWorkspaceFileStack(id: workspaceFolder.id, files: workspace!.files as! [NXWorkspaceBaseFile], stack: &stack) {
                        if !self.outlineView.isItemExpanded(workspace) {
                            self.outlineView.expandItem(workspace)
                        }
                        
                        let last = stack.popLast()
                        for file in stack {
                            if !self.outlineView.isItemExpanded(file) {
                                self.outlineView.expandItem(file)
                            }
                        }
                        let row = self.outlineView.row(forItem: last)
                        self.outlineView.selectRowIndexes([row], byExtendingSelection: false)
                    }
                    
                }
                
                let myVaultIndex = showWorkspace ? 1 : 0
                
                if protectType ==  .myVault {
                    self.type = .myVault
                    self.outlineView.selectRowIndexes(IndexSet([myVaultIndex]), byExtendingSelection: true)
                } else if protectType == .workspace,
                    syncFile == nil {
                    self.type = .workspace
                    self.outlineView.selectRowIndexes(IndexSet([0]), byExtendingSelection: true)
                }
            }
            
        }
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
    
    var projectModel: NXProjectModel? {
        didSet {
            if projectModel != nil {
                destinationStr = (projectModel?.name)! + "/"
                self.type = .project
            }
        }
    }
    var syncFile: NXSyncFile? {
        didSet {
            if syncFile != nil {
                if syncFile?.file is NXProjectFileModel {
                    self.type = .folder
                }
                
                destinationStr = NXCommonUtils.getDestinationString(file: syncFile!.file)
            }
        }
    }
    var       dataArr = [Any]()
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        self.wantsLayer = true
        self.layer?.backgroundColor = RGB(r: 236, g: 236, b: 236).cgColor
    }
    
    func getLastData() -> (type: SelectDestinationType?, project: NXProjectModel?, syncFile: NXSyncFile?) {
        if type == .project {
            return (type, projectModel, nil)
        }else if type == .folder {
            return (type, nil, syncFile)
        } else if type == .workspace {
            return (type, nil, syncFile)
        }
        else {
            return (type, nil, nil)
        }
    }
    
}

extension NXSelectDestinationView: NSOutlineViewDataSource {
    func outlineView(_ outlineView: NSOutlineView, numberOfChildrenOfItem item: Any?) -> Int {
        if item is MyVaultModel {
            return 1
        }else if let rootModel = item as? NXProjectRoot {
            return rootModel.projects.count
        }else if let project = item as? NXProjectModel {
            return project.folders.count
        }else if let folder = item as? NXSyncFile {
            if let fileModel = folder.file as? NXProjectFileModel {
                return fileModel.subFolders.count
            }
            return 0
        } else if let workspace = item as? WorkspaceModel {
            let folders = workspace.files.filter { $0.isFolder }
            return folders.count
        } else if let folder = item as? NXFileBase {
            if let children = folder.children {
                let folders = children.filter { $0.isFolder }
                return folders.count
            }
            
            return 0
        }
        
        return dataArr.count
    }
    
    func outlineView(_ outlineView: NSOutlineView, child index: Int, ofItem item: Any?) -> Any {
        if item == nil  {
            return dataArr[index]
        } else if let rootModel = item as? NXProjectRoot {
            return rootModel.projects[index]
        } else if let project = item as? NXProjectModel {
            return project.folders[index]
        } else if let folder = item as? NXSyncFile {
            if let fileModel = folder.file as? NXProjectFileModel {
                return fileModel.subFolders[index]
            }
            return "bad item"
        } else if let workspace = item as? WorkspaceModel {
            var folders = workspace.files.filter { $0.isFolder }
            folders.sort { $0.name.lowercased() < $1.name.lowercased() }
            return folders[index]
        } else if let file = item as? NXFileBase {
            var folders = file.children!.filter { $0.isFolder }
            folders.sort { $0.name.lowercased() < $1.name.lowercased() }
            return folders[index]
        }
        
        return "bad item"
    }
    
    func outlineView(_ outlineView: NSOutlineView, isItemExpandable item: Any) -> Bool {
        if item is MyVaultModel {
            return false
        }else if let rootModel = item as? NXProjectRoot {
            return rootModel.projects.count > 0
        }else if let project = item as? NXProjectModel {
            return project.folders.count > 0
        }else if let folder = item as? NXSyncFile {
            if let fileModel = folder.file as? NXProjectFileModel {
                return fileModel.subFolders.count > 0
            }
            return false
        } else if let workspace = item as? WorkspaceModel {
            let folders = workspace.files.filter { $0.isFolder }
            if folders.count > 0 {return true}
        } else if let file = item as? NXFileBase {
            if let children = file.children {
                let folders = children.filter { $0.isFolder }
                if folders.count > 0 {return true}
                
            }
            return false
            
        }
        return true
    }
}

extension NXSelectDestinationView: NSOutlineViewDelegate {
    func outlineView(_ outlineView: NSOutlineView, rowViewForItem item: Any) -> NSTableRowView? {
        guard let rowView = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CustomRowView"), owner: self) as? NXCustomRowView else {
            let rowView = NXCustomRowView()
            rowView.identifier = NSUserInterfaceItemIdentifier(rawValue: "CustomRowView")
            return rowView
        }
        return rowView
    }
    
    func outlineView(_ outlineView: NSOutlineView, viewFor tableColumn: NSTableColumn?, item: Any) -> NSView? {
        let cell = outlineView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "destinationCellView"), owner: self) as? NSTableCellView
        cell?.textField?.textColor = NSColor.color(withHexColor: "#353535")
        if let myVault = item as? MyVaultModel {
            cell?.imageView?.image = NSImage.init(named: "MyVault")
            cell?.textField?.stringValue = myVault.name
        } else if let workspace = item as? WorkspaceModel {
            cell?.imageView?.image = NSImage.init(named: "workspace")
            cell?.textField?.stringValue = workspace.name
        } else if item is NXProjectRoot {
            cell?.imageView?.image = NSImage.init(named:"Project")
            cell?.textField?.stringValue = "Project"
        }else if let project = item as? NXProjectModel {
            if project.ownedByMe == true {
            }
            cell?.imageView?.image = NSImage.init(named: (project.ownedByMe == true ? "User" :  "Nouser"))
            cell?.textField?.stringValue = project.name 
        }else if let folder = item as? NXSyncFile {
            if let fileModel = folder.file as? NXProjectFileModel {
                cell?.imageView?.image = NSImage(named: NSImage.folderName)
                cell?.textField?.stringValue = fileModel.name
            }
        } else if let folder = item as? NXFileBase {
            cell?.imageView?.image = NSImage(named: NSImage.folderName)
            cell?.textField?.stringValue = folder.name
        }
        
        return cell
    }
    
    func outlineView(_ outlineView: NSOutlineView, shouldSelectItem item: Any) -> Bool {
        if (item is MyVaultModel || item is NXProjectRoot) {
            type = .myVault
            if destinationBlock != nil {
                destinationBlock!("MyVault")
            }
        } else if let project = item as? NXProjectModel {
            type         = .project
            projectModel = project
        }else if let folder = item as? NXSyncFile {
            type     = .folder
            syncFile = folder
        } else if item is WorkspaceModel {
            type = .workspace
            destinationStr = "Workspace"
        } else if let file = item as? NXWorkspaceBaseFile {
            type = .workspace
            let syncFile = NXSyncFile(file: file)
            syncFile.syncStatus = file.status
            self.syncFile = syncFile
        }
        
        if (type != .myVault && destinationBlock != nil) {
            destinationBlock!(destinationStr)
        }
        return true
    }
    
}

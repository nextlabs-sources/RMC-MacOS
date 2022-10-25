//
//  NXProjectViewController.swift
//  skyDRM
//
//  Created by William (Weiyan) Zhao on 2019/3/14.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

protocol NXProjectViewControllerDelegate: class {
    func openProject(item:Any)
}

class NXProjectViewController: NSViewController {
    @IBOutlet weak var projectTableView: NSTableView!
    @IBOutlet weak var nameTableColumn: NSTableColumn!
    @IBOutlet weak var decriptionTableColumn: NSTableColumn!
    @IBOutlet weak var fileNumberTableColumn: NSTableColumn!
     @IBOutlet weak var emptyFolderLab: NSTextField!
    var orderType: NXListType = .project
    var sortOrder = NXListOrder.name
    var sortAscending = false
    weak var delegate:NXProjectViewControllerDelegate?
    var data:NXProjectNewRoot = NXProjectNewRoot() {
        didSet {
             displayData = data.createByMe + data.createByOthers
             projectTableView.reloadData()
        }
    }
    
    @objc dynamic var displayData = [NXProjectModel]()
    @objc dynamic var displayCount: Int {
        get {
            return displayData.count
        }
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
              initView()
    }
}
extension NXProjectViewController {
    
    func filterCompletioned() {
    
    }
    fileprivate func itemComparator<T: Comparable>(lhs: T, rhs: T, ascending: Bool) -> Bool {
        return ascending ? (lhs < rhs) : (lhs > rhs)
    }
    
    func getOrderFiles(projects: [NXProjectModel], sortOrder:NXListOrder , ascending: Bool) -> [NXProjectModel] {
        var sortedProjects: [NXProjectModel] = []
        switch sortOrder {
        case .name:
            sortedProjects = projects.sorted {
                    return itemComparator(lhs: $0.name.lowercased(), rhs: $1.name.lowercased(), ascending: ascending)
                }
        default:
            break
        }
        return sortedProjects
    }
    
    fileprivate func sortContentOrderBy(_ sortOrder: NXListOrder, ascending: Bool) {
        self.displayData = getOrderFiles(projects: self.data.createByMe, sortOrder: sortOrder, ascending: ascending) + getOrderFiles(projects: self.data.createByOthers, sortOrder: sortOrder, ascending: ascending)
    }
    
    fileprivate func initSortDescriptor() {
        if let tableColumn = projectTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "name")) {
            let sortDescriptor = NSSortDescriptor.init(key: "name", ascending: self.sortOrder == .name ?(!self.sortAscending):true)

            tableColumn.sortDescriptorPrototype = sortDescriptor
        }
    }
    
    func sortTableviewOrderByName(){
        if let tableColumn = projectTableView.tableColumn(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "name")) {
            if tableColumn.sortDescriptorPrototype?.ascending == true{
                sortContentOrderBy(NXListOrder.name, ascending: false)
                let sortDescriptor = NSSortDescriptor.init(key: "name", ascending: false)
                tableColumn.sortDescriptorPrototype = sortDescriptor
            } else {
                let sortDescriptor = NSSortDescriptor.init(key: "name", ascending: true)
                sortContentOrderBy(NXListOrder.name, ascending: true)
                tableColumn.sortDescriptorPrototype = sortDescriptor
            }
        }
        self.projectTableView.reloadData()
    }
    
    fileprivate func initView() {
        initSortDescriptor()
        projectTableView.delegate = self
        projectTableView.dataSource = self
        projectTableView.doubleAction = #selector(tableViewDoubleClick(_:))
    }
    @objc func tableViewDoubleClick(_ sender:Any) {
        openProject()
    }
}

extension NXProjectViewController:NSTableViewDelegate {
    
    func tableView(_ tableView: NSTableView, sortDescriptorsDidChange oldDescriptors: [NSSortDescriptor]) {
        guard let sortDescriptor = tableView.sortDescriptors.first else {
            return
        }
        
        if let key = sortDescriptor.key,
            let order = NXListOrder(rawValue: key) {
            self.sortOrder = order
            self.sortAscending = sortDescriptor.ascending
            
        }
        
        sortContentOrderBy(self.sortOrder, ascending: self.sortAscending)
        self.projectTableView.reloadData()
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        guard let rowView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "CustomRowView"), owner: nil) as? NXCustomRowView else {
            let rowView = NXCustomRowView()
            rowView.identifier = NSUserInterfaceItemIdentifier(rawValue: "CustomRowView")
            return rowView
        }
        return rowView
    }

    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
    guard let indentifier = tableColumn?.identifier,
        let cellView = tableView.makeView(withIdentifier: indentifier, owner: self) else {return nil}
        if indentifier.rawValue == "name" {
            if let iconImage = cellView.viewWithTag(0) as? NSImageView {
              let file = displayData[row]
               if !file.ownedByMe!  {

                iconImage.image = NSImage(named:  "Nouser")


               } else {
                iconImage.image = NSImage(named:  "User")
                }
                if let nameLbl = cellView.viewWithTag(1) as? NSTextField {
                    nameLbl.textColor = NSColor.color(withHexColor: "#353535")
                    nameLbl.stringValue = displayData[row].name
                }
        }
        } else if indentifier.rawValue == "description" {
            if let cell = cellView as? NSTableCellView {
                cell.textField?.textColor = NSColor.color(withHexColor: "#353535")
                cell.textField?.stringValue = displayData[row].projectDescription
        }
        } else if indentifier.rawValue == "fileNumber" {
            if let cell = cellView as? NSTableCellView {
                 cell.textField?.textColor = NSColor.color(withHexColor: "#353535")
                cell.textField?.stringValue = "\(String(describing: displayData[row].totalFiles!)) files"
            }
        }
        return cellView
    }
    func tableView(_ tableView: NSTableView, heightOfRow row: Int) -> CGFloat {
        return 40
    }
}
extension NXProjectViewController:NSTableViewDataSource {

    func numberOfRows(in tableView: NSTableView) -> Int {
        return displayData.count
    }
    
}
extension NXProjectViewController {
    func openProject() {
        if projectTableView.selectedRow == -1 {
            return
        }
        let file = displayData[projectTableView.selectedRow]
        delegate?.openProject(item: file)
        }
    }


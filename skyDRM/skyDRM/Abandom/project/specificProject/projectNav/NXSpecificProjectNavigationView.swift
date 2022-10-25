//
//  NXSpecificProjectNaviationView.swift
//  skyDRM
//
//  Created by helpdesk on 2/21/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa


class NXSpecificProjectNavigationView: NSView {
    @IBOutlet weak var tableView: NSTableView!
    
    weak var delegate: NXSpecificProjectNavDelegate?
    fileprivate var projectInfo = NXProject()
    fileprivate var navItems = [NXSpecificProjectNavCellType]()
    
    private var infoConext = 0

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        
    }
    override func removeFromSuperview() {
        super.removeFromSuperview()
        NXSpecificProjectData.shared.removeObserver(self, forKeyPath: "projectInfo")
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview else {
            return
        }
        wantsLayer = true
        layer?.backgroundColor = BK_COLOR.cgColor
        NXSpecificProjectData.shared.addObserver(self, forKeyPath: "projectInfo", options: .new, context: &infoConext)
        self.projectInfo = NXSpecificProjectData.shared.getProjectInfo().copy() as! NXProject
        tableView.backgroundColor = BK_COLOR
    }

    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &infoConext {
            let gProjectInfo = NXSpecificProjectData.shared.getProjectInfo()
            if gProjectInfo != projectInfo {
                reloadTable(ownedByMe: gProjectInfo.ownedByMe, memberCount: gProjectInfo.totalMembers)
            }
            else if gProjectInfo.totalMembers != projectInfo.totalMembers {
                updateProjectMemberCount(memberCount: gProjectInfo.totalMembers)
            }
            self.projectInfo = gProjectInfo.copy() as! NXProject
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    private func reloadTable(ownedByMe: Bool, memberCount: Int) {
        navItems.removeAll()
        navItems = [NXSpecificProjectNavCellType(navName: NSLocalizedString("PROJECT_HOME", comment: ""), navCount: "", navImg: "project_summary", shouldShowCount: false),
                    NXSpecificProjectNavCellType(navName: NSLocalizedString("PROJECT_FILES", comment: ""), navCount: "", navImg: "project_files", shouldShowCount: false),
                    NXSpecificProjectNavCellType(navName: NSLocalizedString("PROJECT_PEOPLE", comment: ""), navCount: String(memberCount), navImg: "project_members", shouldShowCount: true)]
        if ownedByMe {
            navItems.append(NXSpecificProjectNavCellType(navName: NSLocalizedString("PROJECT_CONFIGURATION", comment: ""), navCount: "", navImg: "project_configuration", shouldShowCount: false))
        }
        
        tableView.reloadData()
        tableView.selectRowIndexes([0], byExtendingSelection: false)
    }
    
    private func updateProjectMemberCount(memberCount: Int) {
        guard tableView.numberOfRows > 2 else {
            return
        }
        guard let cellView = tableView.view(atColumn: 0, row: 2, makeIfNecessary: false) as? NXSpecificProjectNavCellView else {
            return
        }
        DispatchQueue.main.async {
            cellView.navValue = NXSpecificProjectNavCellType(navName: NSLocalizedString("PROJECT_PEOPLE", comment: ""), navCount: "\(memberCount)", navImg: "project_members", shouldShowCount: true)
        }
    }
}

extension NXSpecificProjectNavigationView: NSTableViewDataSource{
    func numberOfRows(in tableView: NSTableView) -> Int {
        return navItems.count
    }
}

extension NXSpecificProjectNavigationView: NSTableViewDelegate{
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        if let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "navCell"), owner: nil) as? NXSpecificProjectNavCellView {
            cellView.navValue = navItems[row]
            return cellView
        }
        return nil
    }
    
    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let myCustomView = NXSpecificProjectNavRowView()
        return myCustomView
    }
    
    func tableViewSelectionDidChange(_ notification: Notification) {
        guard tableView.selectedRow >= 0 else{
            return
        }
        delegate?.onNavigate(index: tableView.selectedRow)
    }
    
}

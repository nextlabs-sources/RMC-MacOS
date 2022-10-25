//
//  NXMainNavigationView.swift
//  skyDRM
//
//  Created by Kevin on 2017/1/26.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

class NXMainNavigationView: NSView, NSTableViewDataSource, NSTableViewDelegate, NXTopArrowViewDelegate {

    @IBOutlet weak var navTableView: NSTableView!
    @IBOutlet weak var bottomView: NSView!
    private var topArrowView: NXTopArrowView!
    weak var mainNavigationDelegate: NXMainNavigationDelegate? = nil
    @IBOutlet weak var helpButton: NSButton!
    
    private var curSelected = -1
    
    private var inited = false
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func viewDidMoveToSuperview(){
        super.viewDidMoveToSuperview()
        
        
    }
    
    func doWork(){
        if inited {
            return
        }
        
        self.layer?.backgroundColor = NSColor.white.cgColor
        
        navTableView.rowHeight = 70
        
        navTableView.selectRowIndexes(NSIndexSet(index: curSelected) as IndexSet, byExtendingSelection: false)
        mainNavigationDelegate?.navButtonClicked(index: curSelected)
        
        Swift.print("xxxx: \(self.frame)")
        Swift.print("yyyy: \(navTableView.frame)")
        
        topArrowView = NXCommonUtils.createViewFromXib(xibName: "NXTopArrowView", identifier: "topArrowView", frame: nil, superView: bottomView) as? NXTopArrowView
        topArrowView?.delegate = self
        var image: NSImage?
        if let client = NXLoginUser.sharedInstance.nxlClient,
            let profile = client.profile,
            let profileImage = NSImage(base64String: profile.avatar)  {
            image = profileImage
        }
        else if let profileImage = NSImage(named:"avatar") {
            image = profileImage
        }
        if image != nil  {
            topArrowView?.setImage(newImage: image!)
        }
        
        inited = true
    }
    
    @IBAction func onTapHelpbutton(_ sender: Any) {
        popHelpVC()
    }
    func popHelpVC() {
        let vc = NXHelpPageViewController()
        NSApplication.shared.keyWindow?.windowController?.contentViewController?.presentAsModalWindow(vc)
    }
    func refreshAvatar() {
        var image: NSImage?
        if let client = NXLoginUser.sharedInstance.nxlClient,
            let profile = client.profile,
            let profileImage = NSImage(base64String: profile.avatar)  {
            image = profileImage
        }
        else if let profileImage = NSImage(named: "avatar") {
            image = profileImage
        }
        if image != nil  {
            topArrowView?.setImage(newImage: image!)
        }
    }
    //NXTopArrowViewDelegate
    func topArrowViewMouseDown() {
        mainNavigationDelegate?.navButtonClicked(index: 1000)
    }
    
    // NSTableView Data Source
    func numberOfRows(in tableView: NSTableView) -> Int {
        return 3
    }

    // this is for view-based
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView?{
        
        let cellView = tableView.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: "navButton"), owner: self) as! NSTableCellView
        
        let Img = cellView.viewWithTag(1) as! NSImageView
        let label = cellView.viewWithTag(2) as! NSTextField
        var selView: NSView? = nil
        
        for tmp in cellView.subviews{
            if tmp.identifier!.rawValue == "selView"{
                selView = tmp
                break
            }
        }
        cellView.layer?.backgroundColor = GREEN_COLOR.cgColor
        switch row {
        case 0:
            if (curSelected == row){
                Img.image = NSImage(named:"home-sel")
                selView?.isHidden = false
            }else{
                Img.image = NSImage(named: "home")
                selView?.isHidden = true
            }
            
            label.stringValue = NSLocalizedString("MAINNAV_HOME", comment: "")
            break
        case 1:
            if (curSelected == row){
                Img.image = NSImage(named: "files-sel")
                selView?.isHidden = false
            }else{
                Img.image = NSImage(named: "files")
                selView?.isHidden = true
            }
            
            label.stringValue = NSLocalizedString("MAINNAV_MYSPACE", comment: "")
            break
        case 2:
            if (curSelected == row){
                Img.image = NSImage(named: "projects-sel")
                selView?.isHidden = false
            }else{
                Img.image = NSImage(named: "projects")
                selView?.isHidden = true
            }
            
            label.stringValue = NSLocalizedString("MAINNAV_PROJECTS", comment: "")
            break
        default:
            break
        }
            
        return cellView
    }

    func tableView(_ tableView: NSTableView, rowViewForRow row: Int) -> NSTableRowView? {
        let myCustomView = NXNavTableRowView()
        return myCustomView
    }
    
    // selection changed
    func tableViewSelectionDidChange(_ notification: Notification) {
        if let myTable = notification.object as? NSTableView {
            // we create an [Int] array from the index set
            let selected = myTable.selectedRowIndexes.map { Int($0) }
            
            Swift.print("cur selected \(selected)")
            
            if selected.count == 0{
                return
            }
            
            if (curSelected == selected[0]){
                Swift.print("selected same row, don't need to do anything")
                return
            }
            curSelected = selected[0]
            
            
            navTableView.reloadData()
            
            navTableView.selectRowIndexes(NSIndexSet(index: curSelected) as IndexSet, byExtendingSelection: false)
            mainNavigationDelegate?.navButtonClicked(index: curSelected)
        }
    }

}

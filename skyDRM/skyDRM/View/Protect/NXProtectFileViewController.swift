//
//  NXProtectFileViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 2018/9/4.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa

protocol NXProtectFileViewControllerDelegate: NSObjectProtocol {
    func protectFinish(_ files: [NXNXLFile], right: NXRightObligation)
    func cancel()
}

class NXProtectFileViewController: NSViewController {
    struct Constant {
        static let kNameIdentifier = "name"
        static let kPathIdentifier = "path"
    }
    
    @IBOutlet weak var tableView: NSTableView!
    @IBOutlet weak var configView: NXProtectFileConfigView!
    
    var data = [String]()
    weak var delegate: NXProtectFileViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        tableView.dataSource = self
        tableView.delegate = self
    }
    
    override func viewWillAppear() {
        super.viewWillAppear()
        
        if let window = self.view.window {
            window.title = "Protect a File"
        }
    }
    @IBAction func cancel(_ sender: Any) {
        self.delegate?.cancel()
    }
    
    
    @IBAction func protect(_ sender: Any) {
    }
    
}

extension NXProtectFileViewController: NSTableViewDataSource {
    func numberOfRows(in tableView: NSTableView) -> Int {
        return data.count
    }
}

extension NXProtectFileViewController: NSTableViewDelegate {
    func tableView(_ tableView: NSTableView, viewFor tableColumn: NSTableColumn?, row: Int) -> NSView? {
        guard
            let identifier = tableColumn?.identifier,
            let cellView = tableView.makeView(withIdentifier: identifier, owner: self),
            let nameLbl = cellView.viewWithTag(0) as? NSTextField,
            let pathLbl = cellView.viewWithTag(1) as? NSTextField
            else { return nil }
        
        let path = data[row]
        let url = URL(fileURLWithPath: path)
        let name = url.lastPathComponent
        nameLbl.stringValue = name
        pathLbl.stringValue = path
        
        return cellView
    }
}

//
//  NXMyOutlineView.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/4/4.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Cocoa

class NXMyOutlineView: NSOutlineView {

    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    func makeView(withIdentifier identifier: String, owner: Any?) -> NSView? {
        let view = super.makeView(withIdentifier: NSUserInterfaceItemIdentifier(rawValue: identifier as String), owner: owner)
        if identifier == NSOutlineView.disclosureButtonIdentifier.rawValue {
            let button: NSButton = view as! NSButton
            button.image = NSImage(named: "folderClose")
            button.alternateImage = NSImage(named: "folderOpen")
            button.isBordered = false
            button.title = ""
            return button
        }
        return view
    }
    
}

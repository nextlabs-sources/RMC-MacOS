//
//  NXCreateNewProjectItem.swift
//  skyDRM
//
//  Created by helpdesk on 2/17/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXCreateNewProjectItem: NSCollectionViewItem {
    weak var delegate:NXCreateNewProjectDelegate?
    @IBOutlet weak var bkBtn: NSButton!
    fileprivate var trackingArea: NSTrackingArea!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        
        if trackingArea != nil {
            bkBtn.removeTrackingArea(trackingArea)
        }
        let trackingRect = bkBtn.bounds
        trackingArea = NSTrackingArea(rect: trackingRect, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: nil)
        bkBtn.addTrackingArea(trackingArea)
    }
    
    @IBAction func onCreateClick(_ sender: Any) {
        guard delegate != nil else{
            return
        }
        delegate?.onCreateProjectCreate()
    }
    
    // mouse event
    override func mouseEntered(with event: NSEvent) {
        super.mouseEntered(with: event)
        NSCursor.pointingHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        super.mouseExited(with: event)
        NSCursor.arrow.set()
    }
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        
    }
}


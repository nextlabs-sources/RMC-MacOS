//
//  NXSpecificProjectHomeRecentFileItem.swift
//  skyDRM
//
//  Created by helpdesk on 2/27/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectHomeRecentFileItem: NSCollectionViewItem {
    @IBOutlet weak var fileName: NSTextField!
    @IBOutlet weak var addTime: NSTextField!
    @IBOutlet weak var fileSize: NSTextField!
    
    weak var delegate:NXSpecificProjectHomeRecentItemDelegate?
    
    fileprivate var trackingArea: NSTrackingArea!
    @IBOutlet weak var bkButton: NSButton!
    
    var itemValue:NXProjectFile?{
        didSet{
            fileName.stringValue = (itemValue?.name)!
            addTime.stringValue = NXCommonUtils.dateFormatSyncWithWebPage(date: (itemValue?.lastModifiedDate)! as Date)
            fileSize.stringValue = NXCommonUtils.formatFileSize(fileSize: (itemValue?.size)!)
        }
    }
    
    @IBAction func itemClick(_ sender: Any) {
        delegate?.onClick(file: itemValue)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        self.view.wantsLayer = true
        self.view.layer?.backgroundColor = NSColor.white.cgColor
        
        if trackingArea != nil {
            bkButton.removeTrackingArea(trackingArea)
        }
        let trackingRect = bkButton.bounds
        trackingArea = NSTrackingArea(rect: trackingRect, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: nil)
        bkButton.addTrackingArea(trackingArea)
    }
    
    //mouse event
    override func mouseEntered(with event: NSEvent) {
        debugPrint("mouse entered")
        super.mouseEntered(with: event)
        NSCursor.pointingHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
        debugPrint("mouse exited")
        super.mouseExited(with: event)
        NSCursor.arrow.set()
    }
    override func mouseDown(with event: NSEvent) {
        debugPrint("mouse down")
        super.mouseDown(with: event)
    }
}

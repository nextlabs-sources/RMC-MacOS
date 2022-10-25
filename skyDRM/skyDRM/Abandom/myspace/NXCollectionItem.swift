//
//  NXCollectionItem.swift
//  skyDRM
//
//  Created by nextlabs on 07/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXCollectionItem: NSCollectionViewItem {
    private var contextMenuView: NXContextMenuView?
    weak var delegate: NXCollectionItemDelegate?
    var id = Int()
    private var bOverlay = false
    private var trackingArea: NSTrackingArea!
    @IBOutlet weak var thumbnailBtn: NSButton!
    @IBOutlet weak var typeImage: NSImageView!
    @IBOutlet weak var infoLabel: NSTextField!
    @IBAction func thumbnailBtnClicked(_ sender: Any) {
        guard delegate != nil else {
            return
        }
        delegate?.thumbnailImageClicked(id: id)
        
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        view.layer?.borderColor = GREEN_COLOR.cgColor
        thumbnailBtn.wantsLayer = true
        thumbnailBtn.layer?.backgroundColor = BK_COLOR.cgColor
        
        typeImage.wantsLayer = true
        typeImage.layer?.backgroundColor = BK_COLOR.cgColor
    }
    override func viewDidAppear() {
        showOverlay(show: false)
        
        guard contextMenuView == nil else {
            return
        }
        contextMenuView = NXCommonUtils.createViewFromXib(xibName: "NXContextMenuView", identifier: "contextMenuView", frame: nil, superView: self.view) as? NXContextMenuView
        if contextMenuView == nil {
            Swift.print("fail to show context menu")
        }
        else {
            contextMenuView?.isHidden = true
        }
    }
    func showOverlay(show: Bool) {
        if show == true {
            thumbnailBtn.isEnabled = false
            if trackingArea != nil {
                thumbnailBtn.removeTrackingArea(trackingArea)
            }
            bOverlay = true
        }
        else {
            thumbnailBtn.isEnabled = true
            if trackingArea != nil {
                thumbnailBtn.removeTrackingArea(trackingArea)
            }
            let trackingRect = thumbnailBtn.bounds
            trackingArea = NSTrackingArea(rect: trackingRect, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: nil)
            thumbnailBtn.addTrackingArea(trackingArea)
            bOverlay = false
        }
    }
    func setHighlight(selected: Bool) {
        view.layer?.borderWidth = selected ? 3.0 : 0.0
    }
    // mouse event
    override func mouseEntered(with event: NSEvent) {
        Swift.print("----- mouse entered, id \(id)")
        super.mouseEntered(with: event)
        NSCursor.pointingHand.set()
    }
    
    override func mouseExited(with event: NSEvent) {
         Swift.print("----- mouse exited, id \(id)")
        
        super.mouseExited(with: event)
        NSCursor.arrow.set()
    }
    override func mouseDown(with event: NSEvent) {
        super.mouseDown(with: event)
        delegate?.collectionItemMouseDown()
        Swift.print("item down")
    }
    @IBAction func operationBtnClicked(_ sender: Any) {
        delegate?.moreBtnClicked(id: id)
        bOverlay = true
    }
}

//
//  NXSpecificProjectHomeView.swift
//  skyDRM
//
//  Created by helpdesk on 2/23/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectHomeView: NSView {
    @IBOutlet weak var descriptionView: NSView!
    @IBOutlet weak var activityStreamView: NSView!
    @IBOutlet weak var recentFilesView: NSView!
    @IBOutlet weak var peopleView: NSView!
    @IBOutlet weak var policiesView: NSView!
    @IBOutlet weak var reportsView: NSView!
    
    @IBOutlet weak var border: NSView!
    fileprivate var nxDescription:NXSpecificProjectHomeDescriptionView?
    var recentFiles:NXSpecificProjectHomeRecentView?
    var people:NXSpecificProjectHomePeopleView?
    
    weak var delegate:NXSpecificProjectHomeDelegate?
    
    struct Constant {
        static let descriptionView = "NXSpecificProjectHomeDescriptionView"
        static let descriptionIdentifier = "NXSpecificProjectHomeDescriptionView"
        
        static let recentFilesView = "NXSpecificProjectHomeRecentView"
        static let recentFileIdentifier = "NXSpecificProjectHomeRecentView"
        
        static let peopleView = "NXSpecificProjectHomePeopleView"
        static let peopleIdentifier = "NXSpecificProjectHomePeopleView"
    }
    
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        border.wantsLayer = true
        border.layer?.borderColor = NSColor.black.cgColor
        border.layer?.borderWidth = 0.3
        
        descriptionView.wantsLayer = true
        descriptionView.layer?.borderWidth = 0.1
        recentFilesView.wantsLayer = true
        recentFilesView.layer?.borderWidth = 0.1
        peopleView.wantsLayer = true
        peopleView.layer?.borderWidth = 0.1
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard let _ = superview else {
            return
        }
        wantsLayer = true
        layer?.backgroundColor = BK_COLOR.cgColor
        nxDescription = NXCommonUtils.createViewFromXib(xibName: Constant.descriptionView, identifier: Constant.descriptionView, frame: nil, superView: descriptionView) as? NXSpecificProjectHomeDescriptionView
        
        recentFiles = NXCommonUtils.createViewFromXib(xibName: Constant.recentFilesView, identifier: Constant.recentFileIdentifier, frame: nil, superView: recentFilesView) as? NXSpecificProjectHomeRecentView
        recentFiles?.delegate = self
        
        people = NXCommonUtils.createViewFromXib(xibName: Constant.peopleView, identifier: Constant.peopleIdentifier, frame: nil, superView: peopleView) as? NXSpecificProjectHomePeopleView
        people?.delegate = self
    }
    
}
extension NXSpecificProjectHomeView:NXSpecificProjectHomeRecentDelegate{
    func viewAllFiles() {
        delegate?.viewAllFiles()
    }
}

extension NXSpecificProjectHomeView:NXSpecificProjectHomePeopleDelegate{
    func viewAllPeople() {
        delegate?.viewAllPeople()
    }
}

//
//  NXSpecificProjectTitleView.swift
//  skyDRM
//
//  Created by helpdesk on 2/21/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectTitleView: NSView {

    @IBOutlet weak var backBtn: NSButton!
    @IBOutlet weak var titlePopup: NSButton!
    
    @IBOutlet weak var addButton: NSButton!
    weak var delegate: NXSpecificProjectTitleDelegate?
    fileprivate var projectInfo = NXProject() {
        didSet {
            if let displayName = projectInfo.displayName,
                displayName != titlePopup.stringValue {
                
                titlePopup.attributedTitle = NSAttributedString(string: displayName, attributes: [ NSAttributedString.Key.foregroundColor : NSColor.white, NSAttributedString.Key.paragraphStyle : titlePstyle,NSAttributedString.Key.font:NSFont.systemFont(ofSize: 16)])
            }
        }
    }
    private let titlePstyle = NSMutableParagraphStyle()
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
        layer?.backgroundColor = GREEN_COLOR.cgColor
        addButton.isHidden = true
        titlePstyle.alignment = .center
        titlePopup.attributedTitle = NSAttributedString(string: "", attributes: [ NSAttributedString.Key.foregroundColor : NSColor.white, NSAttributedString.Key.paragraphStyle : titlePstyle,NSAttributedString.Key.font:NSFont.systemFont(ofSize: 16)])
        NXSpecificProjectData.shared.addObserver(self, forKeyPath: "projectInfo", options: .new, context: &infoConext)
        projectInfo = NXSpecificProjectData.shared.getProjectInfo().copy() as! NXProject
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &infoConext {
            let gProjectInfo = NXSpecificProjectData.shared.getProjectInfo()
            
            projectInfo = gProjectInfo.copy() as! NXProject
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
    
    @IBAction func backAction(_ sender: Any) {
        delegate?.onBackClick()
    }
    
    @IBAction func titleAction(_ sender: Any) {
        delegate?.onTitleClick(projectInfo: projectInfo)
    }
}

//
//  NXSpecificProjectHomeDescriptionView.swift
//  skyDRM
//
//  Created by helpdesk on 3/9/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectHomeDescriptionView: NSView {
    
    private var infoConext = 0
    
    @IBOutlet var textView: NSTextView!
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
        self.wantsLayer = true
        self.layer?.backgroundColor = WHITE_COLOR.cgColor
        NXSpecificProjectData.shared.addObserver(self, forKeyPath: "projectInfo", options: .new, context: &infoConext)
        if let projectDescription = NXSpecificProjectData.shared.getProjectInfo().projectDescription {
            textView.string = projectDescription
        }
    }
    
    override func observeValue(forKeyPath keyPath: String?, of object: Any?, change: [NSKeyValueChangeKey : Any]?, context: UnsafeMutableRawPointer?) {
        if context == &infoConext {
            guard let projectDescription = NXSpecificProjectData.shared.getProjectInfo().projectDescription else {
                return
            }
            if textView.string != projectDescription {
                textView.string = projectDescription
            }
        }
        else {
            super.observeValue(forKeyPath: keyPath, of: object, change: change, context: context)
        }
    }
}

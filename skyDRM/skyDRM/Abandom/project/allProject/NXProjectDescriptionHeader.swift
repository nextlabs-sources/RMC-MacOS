  //
//  NXProjectDescriptionHeader.swift
//  skyDRM
//
//  Created by helpdesk on 2/17/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXProjectHeaderDelegate: NSObjectProtocol {
    func showCollectItem(section: Int, itemnum: Int, expanded: Bool)
    func createProject()
    func viewAllProjects()
}

class NXProjectDescriptionHeader: NSView {

    
    @IBOutlet weak var prefixLabel: NSTextField!
    @IBOutlet weak var suffixLabel: NSTextField!
    @IBOutlet weak var totalNumLabel: NSTextField!
    @IBOutlet weak var arrowBtn: NSButton!
    @IBOutlet weak var viewBtn: NXMouseEventButton!
    weak var delegate: NXProjectHeaderDelegate?
    var shouldHideViewBtn = true {
        willSet {
            DispatchQueue.main.async {
                self.viewBtn.isHidden = newValue
            }
        }
    }
    var shouldShowTotalNumber = true {
        willSet {
            DispatchQueue.main.async {
                self.totalNumLabel.isHidden = !newValue
            }
        }
    }
    var bExpanded = false {
        willSet {
            DispatchQueue.main.async {
                if newValue == false {
                    self.arrowBtn.image = NSImage(named:"arrow-down")
                }
                else {
                    self.arrowBtn.image = NSImage(named: "arrow-up")
                }
            }
        }
    }
    var label: (String, String) = ("", "") {
        willSet {
            DispatchQueue.main.async {
                self.prefixLabel.stringValue = newValue.0
                self.suffixLabel.stringValue = newValue.1
                self.prefixLabel.sizeToFit()
                self.suffixLabel.sizeToFit()
            }
        }
    }
    fileprivate var expandMinNum: Int = -1
    fileprivate var displayedNum: Int = -1
    fileprivate var totalNum: Int = -1
    var section: Int = -1
    func setExpandNumber(expandMinNum: Int, displayedNum: Int, totalNum: Int) {
        self.displayedNum = displayedNum
        self.totalNum = totalNum
        self.expandMinNum = expandMinNum
        DispatchQueue.main.async {
            self.totalNumLabel.stringValue = "(\(totalNum))"
            self.totalNumLabel.sizeToFit()
            if displayedNum > expandMinNum {
                self.arrowBtn.isHidden = false
            }
            else {
                self.arrowBtn.isHidden = true
            }
        }
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        self.viewBtn.isHidden = true
        self.arrowBtn.isHidden = true
        viewBtn.title = NSLocalizedString("PROJECT_SECTION_HEADER_VIEW_ALL_PROJECTS", comment: "")
    }
    @IBAction func onExpand(_ sender: Any) {
        bExpanded = !bExpanded
        if bExpanded ==  false {
            delegate?.showCollectItem(section: section, itemnum: expandMinNum, expanded: bExpanded)
        }
        else {
            delegate?.showCollectItem(section: section, itemnum: displayedNum, expanded: bExpanded)
        }
    }
    @IBAction func onView(_ sender: Any) {
        delegate?.viewAllProjects()
    }
    
}

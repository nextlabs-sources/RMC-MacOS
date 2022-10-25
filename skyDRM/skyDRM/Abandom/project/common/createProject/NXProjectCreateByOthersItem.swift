//
//  NXProjectCreateByOthersItem.swift
//  skyDRM
//
//  Created by helpdesk on 2/17/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXProjectCreateByOthersItem: NSCollectionViewItem {
    @IBOutlet weak var projectName: NSTextField!
    @IBOutlet weak var inviteByOwner: NSTextField!
    @IBOutlet weak var membersView: NXMultiCircleView!
    @IBOutlet weak var ownerNameLabel: NSTextField!
    @IBOutlet weak var bkBtn: NXMouseEventButton!
    
    
    weak var delegate:NXCreateByOtherDelegate?
    
    struct Constant {
        static let maxDisplayMembers = 5
    }
    
    var projectInfo: NXProject?{
        didSet{
            guard isViewLoaded else{
                return
            }
            
            if let projectInfo = projectInfo{
                if let diplayName = projectInfo.displayName {
                    projectName.stringValue = diplayName
                }
                if let ownerName = projectInfo.owner?.name {
                    ownerNameLabel.stringValue = ownerName
                }
            }
            
            if let memberInfoList = projectInfo?.projectMembers {
                var memberNames = [String]()
                for member in memberInfoList {
                    if let displayName = member.displayName {
                        memberNames.append(displayName)
                    }
                }
                membersView.data = memberNames
                membersView.delegate = self
            }
        }
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        
        membersView.maxDisplayCount = Constant.maxDisplayMembers
        inviteByOwner.stringValue = NSLocalizedString("PROJECT_OWNER", comment: "")
    }
    
    @IBAction func onBtn(_ sender: Any) {
        guard let projectInfo = projectInfo else{
            return
        }
        delegate?.onBkBtnClick(projectInfo: projectInfo)
    }
}

extension NXProjectCreateByOthersItem:NXProectCircleViewClickDelegate{
    func mouseEvent(down event: NSEvent){
        guard let projectInfo = projectInfo else{
            return
        }
        delegate?.onBkBtnClick(projectInfo: projectInfo)
    }
}

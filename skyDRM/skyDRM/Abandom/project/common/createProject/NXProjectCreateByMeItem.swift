//
//  NXProjectCreateByItem.swift
//  skyDRM
//
//  Created by helpdesk on 2/17/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXProjectCreateByMeItem: NSCollectionViewItem {
    weak var delegate:NXCreateByMeDelegate?
    
    @IBOutlet weak var membersView: NXMultiCircleView!
    @IBOutlet weak var projectName: NSTextField!
    @IBOutlet weak var fileCounts: NSTextField!
    @IBOutlet weak var inviteBtn: NXMouseEventButton!
    @IBOutlet weak var bkBtn: NXMouseEventButton!
    
    struct Constant {
        static let maxDisplayMembers = 5
    }
    
    var projectInfo: NXProject?{
        didSet{
            guard isViewLoaded else{
                return
            }
            if let projectInfo = projectInfo{
                projectName.stringValue = projectInfo.displayName!
                if projectInfo.totalFiles > 1{
                    fileCounts.stringValue = String(format: NSLocalizedString("PROJECT_FILE_COUNTS", comment: ""), String(projectInfo.totalFiles))
                }else{
                    if projectInfo.totalFiles == 1{
                        fileCounts.stringValue = String(format: NSLocalizedString("PROJECT_FILE_COUNT", comment: ""), String(projectInfo.totalFiles))
                    }else{
                        fileCounts.stringValue = NSLocalizedString("PROJECT_FILE_COUNT_ZERO", comment: "")
                    }
                }
            }else{
                projectName.stringValue = ""
                fileCounts.stringValue = String(format: NSLocalizedString("PROJECT_FILE_COUNT", comment: ""), "0")
            }
            
            if let members = projectInfo?.projectMembers {
                var memberNames = [String]()
                for member in members {
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
        
        inviteBtn.title = NSLocalizedString("PROJECT_INVITE_PEOPLE", comment: "")
        membersView.maxDisplayCount = Constant.maxDisplayMembers
        
    }
    
    @IBAction func invitePeople(_ sender: Any) {
        guard let projectInfo = projectInfo else{
            return
        }
        delegate?.onInviteClick(projectInfo: projectInfo)
    }
    
    @IBAction func onItemClick(_ sender: Any) {
        guard let projectInfo = projectInfo else{
            return
        }
        delegate?.onItemClick(projectInfo: projectInfo)
    }
    
}
extension NXProjectCreateByMeItem:NXProectCircleViewClickDelegate{
    func mouseEvent(down event: NSEvent){
        guard let projectInfo = projectInfo else{
            return
        }
        delegate?.onItemClick(projectInfo: projectInfo)
    }
}


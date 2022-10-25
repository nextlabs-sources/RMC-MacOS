//
//  NXSpecificProjectHomePeopleItemView.swift
//  skyDRM
//
//  Created by helpdesk on 3/8/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectHomePeopleItemView: NSCollectionViewItem {
    @IBOutlet weak var displayName: NSTextField!
    @IBOutlet weak var joinedTime: NSTextField!
    @IBOutlet weak var avatar: NSImageView!
    
    var projectMemberModel:NXProjectMember?
    
    weak var delegate:NXSpecialProjectHomePeopleItemDelegate?
    
    fileprivate var trackingArea: NSTrackingArea!
    
    @IBOutlet weak var bkButton: NSButton!
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        avatar.isHidden = true
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        
        avatar.wantsLayer = true
        avatar.layer?.masksToBounds = true
        avatar.layer?.backgroundColor = BK_COLOR.cgColor
        avatar.imageScaling = .scaleAxesIndependently
        
        if trackingArea != nil {
            bkButton.removeTrackingArea(trackingArea)
        }
        let trackingRect = bkButton.bounds
        trackingArea = NSTrackingArea(rect: trackingRect, options: [.activeAlways, .mouseEnteredAndExited], owner: self, userInfo: nil)
        bkButton.addTrackingArea(trackingArea)
    }
    
    var memberInfo:NXProjectMember?{
        didSet{
            guard isViewLoaded else{
                return
            }
            
            if let memberInfo = memberInfo{
                
                projectMemberModel = memberInfo
                
                let formatter = DateFormatter()
                formatter.locale = Locale(identifier: "en_US_POSIX")
                formatter.dateFormat = "dd MMM yyyy,hh:mm a"
                formatter.amSymbol = "AM"
                formatter.pmSymbol = "PM"
                
                let date = NSDate(timeIntervalSince1970: memberInfo.creationTime)
                let formatJoinTime = formatter.string(from:date as Date)
                
                displayName.stringValue = memberInfo.displayName!
                joinedTime.stringValue = formatJoinTime
                
                var image = NSImage(base64String: memberInfo.avatarBase64)
                if image == nil {
                    image = NSImage(named:"avatar")
                    self.setImage(newImage: image!)
                }else{
                    self.setImage(newImage: image!)
                }
            }else{
                displayName.stringValue = ""
                joinedTime.stringValue = ""
            }
        }
    }
    
    @IBAction func onTapBkButton(_ sender: Any) {
            delegate?.onClickPeopleCellItem(memberModel:projectMemberModel)
    }
    
    func setImage(newImage: NSImage){
        DispatchQueue.main.async{
            self.avatar.layer?.cornerRadius = self.avatar.bounds.width/2
            self.avatar.image = newImage
        }
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

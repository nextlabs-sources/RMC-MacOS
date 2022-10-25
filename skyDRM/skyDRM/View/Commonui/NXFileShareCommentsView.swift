//
//  NXFileShareCommentsView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 11/07/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXFileShareCommentsView: NSView {

    @IBOutlet weak var contentView: NSView!
    fileprivate var commentsView: NXCommentsView?
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        // Drawing code here.
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        commentsView = NXCommonUtils.createViewFromXib(xibName: "NXCommentsView", identifier: "commentsView", frame: nil, superView: contentView) as? NXCommentsView
        commentsView?.placeholder = NSLocalizedString("COMMENT_VIEW_SHARE_COMMENT", comment: "")
    }
    func comments() -> String {
        return commentsView?.comments ?? ""
    }
}

//
//  NXNetworkStatusView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 31/10/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXNetworkStatusView: NSView {
//    @IBOutlet weak var leftLine: NSBox!
    @IBOutlet weak var rightLine: NSBox!
    @IBOutlet weak var statusLabel: NSTextField!
    @IBOutlet weak var leftLine: NSBox!
    struct Constant {
        static let offlineColor = NSColor(colorWithHex: "#EB5757", alpha: 1)!
        static let onlineColor = NSColor(colorWithHex: "#27AE60", alpha: 1)!
    }
    var isOffline = true {
        didSet {
            DispatchQueue.main.async {
                self.layer?.backgroundColor = NSColor.white.cgColor
                if self.isOffline {
                    self.rightLine.borderColor = Constant.offlineColor
                    self.leftLine.borderColor = Constant.offlineColor
                    self.leftLine.fillColor = Constant.offlineColor
                    self.statusLabel.textColor = Constant.offlineColor
                    self.statusLabel.stringValue = NSLocalizedString("NETWORK_STATUS_OFFLINE", comment: "")
                }
                else {
                    self.rightLine.borderColor = Constant.onlineColor
                    self.leftLine.borderColor = Constant.onlineColor
                    self.leftLine.fillColor = Constant.onlineColor
                    self.statusLabel.textColor = Constant.onlineColor
                    self.statusLabel.stringValue = NSLocalizedString("NETWORK_STATUS_ONLINE", comment: "")
                }
            }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        isOffline = true
    }
}

//
//  NXProgressIndicatorView.swift
//  SkyDrmUITest
//
//  Created by nextlabs on 09/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXMySpaceIndicatorViewDelegate: NSObjectProtocol {
    func viewMyDrive()
    func viewMyVault()
}

class NXMySpaceIndicatorView: NSView {


    @IBOutlet weak var leftView: NSView!
    @IBOutlet weak var midView: NSView!
    @IBOutlet weak var rightView: NSView!
    
    fileprivate var myDriveView: NXDriveIndicatorView?
    fileprivate var myVaultView: NXDriveIndicatorView?
    private var totalView: NXTotalIndicatorView?
    private var myDrive: Int64 = 0
    private var myVault: Int64 = 0
    private var used: Int64 = 0
    private var total: Int64 = 0
    
    weak var delegate: NXMySpaceIndicatorViewDelegate?
    
    private let mydriveColor = NSColor(red: 52/255, green: 153/255, blue: 76/255, alpha: 1.0)
    private let myvaultColor = NSColor(red: 79/255, green: 79/255, blue: 79/255, alpha: 1.0)
    
    override func removeFromSuperview() {
        super.removeFromSuperview()
        totalView?.removeFromSuperview()
        myDriveView?.removeFromSuperview()
        myVaultView?.removeFromSuperview()
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        if let _ = superview {
            myDriveView = NXCommonUtils.createViewFromXib(xibName: "NXDriveIndicatorView", identifier: "driveIndicatorView", frame: nil, superView: midView) as? NXDriveIndicatorView
            myDriveView?.delegate = self
            myDriveView?.color = mydriveColor
            myDriveView?.name = "MyDrive"
            myDriveView?.driveImage = NSImage(named:"mydrive")
            myDriveView?.view = NSLocalizedString("HOME_TOPVIEW_INDICATORVIEW_VIEW_FILES", comment: "")
            myVaultView = NXCommonUtils.createViewFromXib(xibName: "NXDriveIndicatorView", identifier: "driveIndicatorView", frame: nil, superView: rightView) as? NXDriveIndicatorView
            myVaultView?.delegate = self
            myVaultView?.color = myvaultColor
            myVaultView?.name = "MyVault"
            myVaultView?.driveImage = NSImage(named:"myvault")
            myVaultView?.view = NSLocalizedString("HOME_TOPVIEW_INDICATORVIEW_VIEW_PROTECTED_FILES", comment: "")
            totalView = NXCommonUtils.createViewFromXib(xibName: "NXTotalIndicatorView", identifier: "totalIndicatorView", frame: nil, superView: leftView) as? NXTotalIndicatorView
            totalView?.mydriveColor = mydriveColor
            totalView?.myvaultColor = myvaultColor
        }
    }
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)
        drawProgressInternal()
    }
    func drawProgress(used: Int64, myVault: Int64, total: Int64) {
        self.used = used
        self.myVault = myVault
        self.total = total
        self.myDrive = self.used - self.myVault
        self.needsDisplay = true
    }
    private func calcMyDrive() {
        let myVaultStr = NXCommonUtils.formatFileSize(fileSize: myVault, precision: 1)
        let usedStr = NXCommonUtils.formatFileSize(fileSize: used, precision: 3)
        self.myVault = NXCommonUtils.CalculateFileSize(fileSize: myVaultStr)
        self.used = NXCommonUtils.CalculateFileSize(fileSize: usedStr)
        if self.used >= self.myVault {
            self.myDrive = self.used - self.myVault
        }
        else {
            self.myDrive = 0
            self.used = self.myVault
        }
        
    }
    private func drawProgressInternal(){
        totalView?.drawTotalIndicator(myDrive: myDrive, myVault: myVault, total: total)
        
        let myDriveStr = NXCommonUtils.formatFileSize(fileSize: myDrive, precision: 1)
        let myVaultStr = NXCommonUtils.formatFileSize(fileSize: myVault, precision: 1)
        myDriveView?.size = myDriveStr
        myVaultView?.size = myVaultStr
        
    }
    
}
extension NXMySpaceIndicatorView: NXDriveIndicatorViewDelegate {
    func onView(sender: Any) {
        if sender as? NXDriveIndicatorView == myDriveView {
            delegate?.viewMyDrive()
        }
        else if sender as? NXDriveIndicatorView  == myVaultView {
            delegate?.viewMyVault()
        }
    }
}

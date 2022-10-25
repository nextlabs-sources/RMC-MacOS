//
//  NXProgressIndicatorView.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/27.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa
@objc protocol NXProgressIndicatorDelegate: NSObjectProtocol {
    @objc optional func onPICancel()
}
class NXProgressIndicatorView: NSView {
    
    private var backgroundBtn: NSButton?
    private var indicator: NSProgressIndicator?
    private var cancelBtn: NSButton?
    private var isClosable = false
    private var useDefaultFrame = true
    
    struct Constant {
        static let cancelWidth: CGFloat = 150
        static let cancelHeight: CGFloat = 50
        static let cancelIndicatorGap: CGFloat = 30
        static let indicator:CGFloat = 20
    }
    weak var piDelegate: NXProgressIndicatorDelegate?
    
    func setClose(isClosable: Bool) {
        self.isClosable = isClosable
    }
    func setCancelButtonFrame(frame: NSRect) {
        cancelBtn?.frame = frame
        useDefaultFrame = false
    }
    
    override var frame: NSRect {
        willSet {
            backgroundBtn?.frame = newValue
            indicator?.frame = NSMakeRect(newValue.width/2-Constant.indicator/2, newValue.height/2-Constant.indicator/2, Constant.indicator, Constant.indicator)
            if useDefaultFrame {
                updateCancelBtnFrame()
            }
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
    }
    override func removeFromSuperview() {
        super.removeFromSuperview()
        backgroundBtn?.removeFromSuperview()
        backgroundBtn = nil
        indicator?.removeFromSuperview()
        indicator = nil
        cancelBtn?.removeFromSuperview()
        cancelBtn = nil
    }
    override func viewDidMoveToSuperview() {
        super.viewDidMoveToSuperview()
        guard superview != nil else {
            return
        }
        
        self.indicator = {
            let indicator = NSProgressIndicator()
            indicator.style = .spinning
            indicator.frame = NSMakeRect(frame.width/2-Constant.indicator/2, frame.height/2-Constant.indicator/2, Constant.indicator, Constant.indicator)
            self.addSubview(indicator)
            indicator.isHidden = true
            
            return indicator
        }()
        
        self.backgroundBtn = {
            let backgroundBtn = NSButton()
            backgroundBtn.isBordered = false
            backgroundBtn.setButtonType(.momentaryPushIn)
            backgroundBtn.bezelStyle = .regularSquare
            backgroundBtn.title = ""
            backgroundBtn.frame = self.frame
            backgroundBtn.alphaValue = 0.8
            backgroundBtn.wantsLayer = true
            backgroundBtn.layer?.backgroundColor = NSColor.gray.cgColor
            self.addSubview(backgroundBtn)
            backgroundBtn.isHidden = true
            
            return backgroundBtn
        }()
        
        self.cancelBtn = {
            let cancelBtn = NSButton()
            cancelBtn.isBordered = false
            cancelBtn.setButtonType(.momentaryPushIn)
            cancelBtn.bezelStyle = .regularSquare
            cancelBtn.title = NSLocalizedString("REPOSITORY_CANCEL", comment: "")
            cancelBtn.wantsLayer = true
            cancelBtn.layer?.backgroundColor = NSColor.white.cgColor
            cancelBtn.isHidden = true
            cancelBtn.alphaValue = 0.8
            cancelBtn.target = self
            cancelBtn.action = #selector(onCancelAnimation(_:))
            self.addSubview(cancelBtn)
            return cancelBtn
        }()
    }
    func startAnimation() {
        self.indicator?.isHidden = false
        self.backgroundBtn?.isHidden = false
        self.backgroundBtn?.frame = self.frame
        self.indicator?.startAnimation(nil)
        if self.isClosable {
            self.cancelBtn?.isHidden = false
        }
        if useDefaultFrame {
            updateCancelBtnFrame()
        }
    }
    func stopAnimation() {
        DispatchQueue.main.async {
            self.indicator?.isHidden = true
            self.backgroundBtn?.isHidden = true
            self.indicator?.stopAnimation(nil)
            self.cancelBtn?.isHidden = true
        }
     
    }
    @IBAction func onCancelAnimation(_ sender: Any) {
        piDelegate?.onPICancel?()
    }
    private func updateCancelBtnFrame() {
        cancelBtn?.frame = NSMakeRect(frame.width/2-Constant.cancelWidth/2, (indicator?.frame.minY ?? frame.height/2) - Constant.cancelIndicatorGap - Constant.cancelHeight, Constant.cancelWidth, Constant.cancelHeight)
    }
}

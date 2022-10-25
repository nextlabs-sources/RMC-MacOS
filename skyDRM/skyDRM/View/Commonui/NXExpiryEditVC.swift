//
//  NXExpiryEditVC.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 27/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXExpiryEditVCDelegate: NSObjectProtocol {
    func onSelect(expiry: NXFileExpiry)
}

class NXExpiryEditVC: NSViewController {

    @IBOutlet weak var contentView: NSView!
    private var neverView: NXExpiryNeverView?
    private var relativeView: NXExpiryRelativeView?
    private var absoluteView: NXExpiryAbsoluteView?
    private var rangeView: NXExpiryRangeView?
    @IBOutlet weak var neverRadio: NSButton!
    @IBOutlet weak var relativeRadio: NSButton!
    @IBOutlet weak var absoluteRadio: NSButton!
    @IBOutlet weak var rangeRadio: NSButton!
    @IBOutlet weak var cancelBtn: NSButton!
    @IBOutlet weak var selectBtn: NSButton!
    weak var delegate: NXExpiryEditVCDelegate?
    
    // Input
    var expiry: NXFileExpiry! {
        didSet {
            type = expiry.type
            switch type {
            case .neverExpire:
                showNeverView()
                
            case .relativeExpire:
                showRelativeView(expiry: self.expiry)
                
            case .absoluteExpire:
                showAbsoluteView(expiry: self.expiry)
                
            case.rangeExpire:
                showRangeView(expiry: self.expiry)
                
            }
        }
    }
    
    fileprivate var type: NXExpiryType = .neverExpire
    
    @IBAction func onSelecte(_ sender: Any) {
        let expiry: NXFileExpiry
        switch type {
        case .neverExpire:
            expiry = NXFileExpiry(type: .neverExpire, start: nil, end: nil)
        case .relativeExpire:
            expiry = NXFileExpiry(type: .relativeExpire, start: nil, end: relativeView?.endDate)
        case .absoluteExpire:
            expiry = NXFileExpiry(type: .absoluteExpire, start: nil, end: absoluteView?.endDate)
        case .rangeExpire:
            expiry = NXFileExpiry(type: .rangeExpire, start: rangeView?.startDate, end: rangeView?.endDate)
        }
        
        delegate?.onSelect(expiry: expiry)
        presentingViewController?.dismiss(self)
    }
    @IBAction func onCancel(_ sender: Any) {
        presentingViewController?.dismiss(self)
    }
    
    deinit {
        print("release")
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        view.wantsLayer = true
        view.layer?.backgroundColor = NSColor.white.cgColor
        cancelBtn.wantsLayer = true
        cancelBtn.layer?.cornerRadius = 5
        selectBtn.wantsLayer = true
        selectBtn.layer?.cornerRadius = 5
        let titleAttr = NSMutableAttributedString(attributedString: selectBtn.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor.white], range: NSMakeRange(0, selectBtn.title.count))
        selectBtn.attributedTitle = titleAttr
        
        let startColor = NSColor.init(colorWithHex: NXConstant.NXColor.linear.0)!
        let endColor = NSColor.init(colorWithHex: NXConstant.NXColor.linear.1)!
        let gradientLayer = NXCommonUtils.createLinearGradientLayer(frame: selectBtn.bounds, start: startColor, end: endColor)
        selectBtn.layer?.addSublayer(gradientLayer)
        location()
        
        initView()
    }
    
    private func initView() {
        neverView = NXCommonUtils.createViewFromXib(xibName: "NXExpiryNeverView", identifier: "expiryNeverView", frame: nil, superView: contentView) as? NXExpiryNeverView
        
        relativeView = NXCommonUtils.createViewFromXib(xibName: "NXExpiryRelativeView", identifier: "expiryRelativeView", frame: nil, superView: contentView) as? NXExpiryRelativeView
        
        absoluteView = NXCommonUtils.createViewFromXib(xibName: "NXExpiryAbsoluteView", identifier: "expiryAbsoluteView", frame: nil, superView: contentView) as? NXExpiryAbsoluteView
        
        rangeView = NXCommonUtils.createViewFromXib(xibName: "NXExpiryRangeView", identifier: "expiryRangeView", frame: nil, superView: contentView) as? NXExpiryRangeView
        
        hideAll()
        
    }
    
    override func viewDidAppear() {
        super.viewDidAppear()
        view.window?.title = NXConstant.kTitle // "Specify Rights Expiry Date"
        self.view.window?.styleMask.remove(.resizable)
    }
    @IBAction func onRadioClick(_ sender: Any) {
        guard let radio = sender as? NSButton else {
            return
        }
        if radio.tag == 1 {
            showNeverView()
            type = .neverExpire
        }
        else if radio.tag == 2 {
            showRelativeView(expiry: nil)
            type = .relativeExpire
        }
        else if radio.tag == 3 {
            showAbsoluteView(expiry: nil)
            type = .absoluteExpire
        }
        else {
            showRangeView(expiry: nil)
            type = .rangeExpire
        }
    }
    fileprivate func location() {
        neverRadio.title = "FILE_RIGHT_EXPIRE".localized
        relativeRadio.title = "FILE_RIGHT_RELATIVE".localized
        absoluteRadio.title = "FILE_RIGHT_ABSOLUTEDATE".localized
        rangeRadio.title = "FILE_RIGHT_DATERANGE".localized
    }
    
    private func hideAll() {
        neverView?.isHidden = true
        relativeView?.isHidden = true
        absoluteView?.isHidden = true
        rangeView?.isHidden = true
    }

    private func showNeverView() {
        hideAll()
        
        neverView?.isHidden = false
        let titleAttr = NSMutableAttributedString(attributedString: neverRadio.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor(colorWithHex: "#27AE60")!], range: NSMakeRange(0, neverRadio.title.count))
        neverRadio.attributedTitle = titleAttr
        neverRadio.state = NSControl.StateValue.on
    }
    
    private func showRelativeView(expiry: NXFileExpiry?) {
        hideAll()
        
        relativeView?.isHidden = false
        let titleAttr = NSMutableAttributedString(attributedString: relativeRadio.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor(colorWithHex: "#27AE60")!], range: NSMakeRange(0, relativeRadio.title.count))
        relativeRadio.attributedTitle = titleAttr
        relativeRadio.state = NSControl.StateValue.on
        
        if let end = expiry?.end {
            relativeView?.endDate = end
        }
    }
    
    private func showAbsoluteView(expiry: NXFileExpiry?) {
        hideAll()
        
        absoluteView?.isHidden = false
        let titleAttr = NSMutableAttributedString(attributedString: absoluteRadio.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor(colorWithHex: "#27AE60")!], range: NSMakeRange(0, absoluteRadio.title.count))
        absoluteRadio.attributedTitle = titleAttr
        absoluteRadio.state = NSControl.StateValue.on
        
        if let end = expiry?.end {
            absoluteView?.endDate = end
        }
    }
    
    private func showRangeView(expiry: NXFileExpiry?) {
        hideAll()
        
        rangeView?.isHidden = false
        let titleAttr = NSMutableAttributedString(attributedString: rangeRadio.attributedTitle)
        titleAttr.addAttributes([NSAttributedString.Key.foregroundColor: NSColor(colorWithHex: "#27AE60")!], range: NSMakeRange(0, rangeRadio.title.count))
        rangeRadio.attributedTitle = titleAttr
        rangeRadio.state = NSControl.StateValue.on
        
        if let start = expiry?.start,
            let end = expiry?.end {
            rangeView?.initialize(startDate: start, endDate: end)
        }
        
    }
    
    fileprivate func endOfDay(date: Date) -> Date {
        var component = Calendar.current.dateComponents([.month, .year, .day, .hour, .minute, .second], from: date)
        component.hour = 23
        component.minute = 59
        component.second = 59
        return Calendar.current.date(from: component) ?? Date()
    }
    fileprivate func beginOfDay(date: Date) -> Date {
        var component = Calendar.current.dateComponents([.month, .year, .day, .hour, .minute, .second], from: date)
        component.hour = 0
        component.minute = 0
        component.second = 0
        return Calendar.current.date(from: component) ?? Date()
    }
}

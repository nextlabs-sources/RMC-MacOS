//
//  CircleText.swift
//  CircleControllerDemo
//
//  Created by pchen on 22/02/2017.
//  Copyright © 2017 pchen. All rights reserved.
//

import Cocoa

protocol MouseEventDelegate: NSObjectProtocol {
    func mouseEvent(entered event: NSEvent)
    func mouseEvent(exited event: NSEvent)
    func mouseEvent(down event: NSEvent)
}

class NXCircleText: NSView {

    fileprivate struct Constant {
        static let smallFontSize: CGFloat = 12
        static let defaultFontSize: CGFloat = 20
        static let defaultBackgroundColor: NSColor = .red
        static let defaultTextFont: NSFont = NSFont.systemFont(ofSize: defaultFontSize)
        static let defaultTextColor: NSColor = .white
        static let defaultRadius: CGFloat = 15
    }
    
    override init(frame frameRect: NSRect) {
        super.init(frame: frameRect)
        
        _radius = min(frameRect.width, frameRect.height)/2
    }
    
    required init?(coder decoder: NSCoder) {
        super.init(coder: decoder)
        
        _radius = min(self.bounds.height, self.bounds.height)/2
    }
    
    // Input.
    var text: String = "" {
        didSet {
            updateText()
        }
    }
    
    var textColor: NSColor = Constant.defaultTextColor {
        didSet {
            wantsLayer = true
            textLayer.foregroundColor = textColor.cgColor
        }
    }
    
    var font: NSFont = Constant.defaultTextFont {
        didSet {
            updateText()
        }
    }
    
    private var _radius: CGFloat = Constant.defaultRadius
    var radius: CGFloat {
        get {
            return _radius
        }
        set {
            _radius = newValue
            updateCircle()
        }
    }
    
    var backgroundColor: NSColor = Constant.defaultBackgroundColor {
        didSet {
            wantsLayer = true
            layer?.backgroundColor = backgroundColor.cgColor
        }
    }
    
    var extInfo: String = ""
    
    weak var delegate: MouseEventDelegate?
    
    private var textLayer = CATextLayer()
    
    override func viewDidMoveToWindow() {
        super.viewDidMoveToWindow()
        guard let _ = self.window else {
            return
        }
        
        initView()
    }
    
    func initView() {
        updateCircle()
        updateText()
        self.layer?.addSublayer(textLayer)
    }
    
    private func updateCircle() {
        wantsLayer = true
        let frame = CGRect(x: 0, y: 0, width: 2 * radius, height: 2 * radius)
        layer?.bounds = frame
        layer?.cornerRadius = radius
        layer?.backgroundColor = backgroundColor.cgColor
        addTrackingArea()
    }
    
    // Update Text Layer
    private func updateText() {
        let rect = CGRect(x: 0, y: 0, width: 2 * radius, height: 2 * radius)
        let fontSize = getFontSize(from: font)
        textLayer.fontSize = fontSize ?? Constant.defaultFontSize
        textLayer.font = font
        textLayer.string = text
        textLayer.isWrapped = true
        textLayer.alignmentMode = CATextLayerAlignmentMode.center
        textLayer.foregroundColor = textColor.cgColor
        
        // Set text layer frame.
        let textSize = getTextSize(with: text, font: font)
        let x = (rect.width - textSize.width)/2
        let y = (rect.height - textSize.height)/2
        let origin = CGPoint(x: x, y: y)
        
        // Remove implicit animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        textLayer.frame = CGRect(origin: origin, size: textSize)
        CATransaction.commit()
    }
    
    private func addTrackingArea() {
        if let _ = self.trackingAreas.last {
            return
        }
        let rect = CGRect(x: 0, y: 0, width: 2 * radius, height: 2 * radius)
        let ops: NSTrackingArea.Options = [NSTrackingArea.Options.activeAlways, NSTrackingArea.Options.mouseEnteredAndExited]
        let trackingArea = NSTrackingArea(rect: rect, options: ops, owner: self, userInfo: nil)
        self.addTrackingArea(trackingArea)
    }
    
    override func mouseEntered(with event: NSEvent) {
        if !extInfo.isEmpty {
             toolTip = extInfo
        }
        delegate?.mouseEvent(entered: event)
    }
    
    override func mouseExited(with event: NSEvent) {
        delegate?.mouseEvent(exited: event)
    }

    override func mouseDown(with event: NSEvent) {
        delegate?.mouseEvent(down: event)
    }
}

extension NXCircleText {
    func getFontSize(from font: NSFont) -> CGFloat? {
        return font.fontDescriptor.object(forKey: NSFontDescriptor.AttributeName.size) as? CGFloat
    }
    
    func getTextSize(with text: String, font: NSFont) -> CGSize {
        let string = NSString(string: text)
        return string.size(withAttributes: [NSAttributedString.Key.font: font])
    }
}

//
//  MultiCircleView.swift
//  CircleControllerDemo
//
//  Created by Paul (Qian) Chen on 22/05/2017.
//  Copyright © 2017 pchen. All rights reserved.
//

import Cocoa

class NXMultiCircleView: NSView {

    fileprivate struct Constant {
        static let defaultMaxDisplayCount = 3
        static let defaultCirleSeparator: CGFloat = -8
        static let defaultLastCircleSeparator: CGFloat = 8
        
        static let defaultBackgroundColor: NSColor = .blue
    }
    
    weak var delegate: NXProectCircleViewClickDelegate?
    // Input
    var isLastDataMoreCount: Bool = false
    var data = [String]() {
        didSet {
            updateCircle()
        }
    }
    
    // Setting
    var maxDisplayCount: Int = Constant.defaultMaxDisplayCount {
        didSet {
            updateCircle()
        }
    }
    
    // View Setting
    var circleSeparator: CGFloat = Constant.defaultCirleSeparator {
        didSet {
            updateCircle()
        }
    }
    var lastCircleSeparator: CGFloat = Constant.defaultLastCircleSeparator {
        didSet {
            updateCircle()
        }
    }
    var backgoundColor: NSColor = Constant.defaultBackgroundColor {
        didSet {
            wantsLayer = true
            layer?.backgroundColor = backgoundColor.cgColor
        }
    }
    
    override func draw(_ dirtyRect: NSRect) {
        super.draw(dirtyRect)

        // Drawing code here.
        
        updateCircle()
    }
    
    private func updateCircle() {
        clearSubView()
        for i in 0..<maxDisplayCount {
            createCircle(with: i)
        }
    }
    
    private func clearSubView() {
        for view in subviews {
            view.removeFromSuperview()
        }
    }
    
    private func createCircle(with index: Int) {
        
        if index >= data.count {
            return
        }
        
        let radius = min(bounds.width, bounds.height)/2
        let y: CGFloat = 0
        
        if index != maxDisplayCount {
            let x: CGFloat = (2 * radius + circleSeparator) * CGFloat(index)
            let content: String = data[index]
            let circle = NXCircleText(frame: NSRect(x: x, y: y, width: 2 * radius, height: 2 * radius))
            
            let info = fetchTextAbbrevAndColor(with: content)
            circle.text = info.abbrev
            circle.backgroundColor = info.color
            circle.delegate = self
            
            addSubview(circle)
            
        } else {
            let x: CGFloat = (2 * radius + circleSeparator) * CGFloat(maxDisplayCount - 1) + 2 * radius + lastCircleSeparator
            let content = "+" + ((isLastDataMoreCount) ? data[index]: String(data.count - maxDisplayCount))
            let circle = NXCircleText(frame: NSRect(x: x, y: y, width: 2 * radius, height: 2 * radius))
            
            circle.text = content
            circle.backgroundColor = NSColor(colorWithHex: "#70B55B", alpha: 1.0)!
            circle.delegate = self
            
            addSubview(circle)
        }
        
    }
}

extension NXMultiCircleView {
    
    func fetchTextAbbrevAndColor(with data: String) -> (abbrev: String, color: NSColor) {
        let abbrev = NXCommonUtils.abbreviation(forUserName: data)
        let firstLowLetter = String(abbrev[..<abbrev.index(after: abbrev.startIndex)])
        var backgroundColor = NSColor.red
        if let colorValue = NXCommonUtils.circleViewBKColor[firstLowLetter] {
            backgroundColor = NSColor(colorWithHex: colorValue, alpha: 1.0)!
        }
        
        return (abbrev, backgroundColor)
    }
}

extension NXMultiCircleView:MouseEventDelegate{
    func mouseEvent(entered event: NSEvent){
        
    }
    
    func mouseEvent(exited event: NSEvent){
        
    }
    
    func mouseEvent(down event: NSEvent){
        delegate?.mouseEvent(down: event)
    }
}

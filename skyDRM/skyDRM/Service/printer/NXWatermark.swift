//
//  NXWatermark.swift
//  PrinterDemo
//
//  Created by Bill (Guobin) Zhang on 4/17/17.
//  Copyright © 2017 Bill (Guobin) Zhang. All rights reserved.
//

import Cocoa

class NXWatermark : NSObject {
    struct Constant {
        var kWidthSpace:CGFloat = 50
        var kHeightSpace:CGFloat = 50
    }
    var constant:Constant
    var text:String
    var radianAngle:CGFloat
    var font:NSFont
    var textColor:NSColor
    var backgroundColor:NSColor
    
    var unitWidth:CGFloat {
        get {
           return unitSize().width
        }
    }
    var unitHeight:CGFloat {
        get {
            return unitSize().height
        }
    }
    
    init(overlayInfo:NXOverlayInfo) {
        self.constant = NXWatermark.Constant(kWidthSpace: 50, kHeightSpace: 50)
        self.text = overlayInfo.text
        self.radianAngle = overlayInfo.isClockwiserotation ? -CGFloat(Double.pi/4):CGFloat(Double.pi/4)
        self.font = overlayInfo.font
        self.textColor = overlayInfo.textColor
        self.backgroundColor = NSColor.clear
    }
    
    init(constant:NXWatermark.Constant, text:String, radianAngle:CGFloat, font:NSFont, textColor:NSColor, backgroundColor:NSColor) {
        self.constant = constant
        self.text = text
        self.radianAngle = radianAngle
        self.font = font
        self.textColor = textColor
        self.backgroundColor = backgroundColor
    }
    
    func unitSize() -> CGSize {
        guard let unitSize = self.attributeString()?.size() else {
            return CGSize(width: 0, height: 0)
        }
        let angle = fabsf(Float(radianAngle))
        let width = unitSize.width * CGFloat(cosf(angle)) + unitSize.height * CGFloat(sinf(angle))
        let height = unitSize.width * CGFloat(sinf(angle)) + unitSize.height * CGFloat(cosf(angle))
        
        return CGSize(width: width, height: height)
    }

    func attributeString()->NSAttributedString? {
        let attributes = NSDictionary(dictionary: [NSAttributedString.Key.foregroundColor: textColor,
                                                   NSAttributedString.Key.font:font,
                                                   NSAttributedString.Key.backgroundColor:backgroundColor
            ])
        return NSAttributedString(string:text, attributes: attributes as? [NSAttributedString.Key : Any])
    }
}

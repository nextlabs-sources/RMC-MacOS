//
//  NSColor+HexColor.swift
//  skyDRM
//
//  Created by Bill (Guobin) Zhang on 4/21/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

extension NSColor {
    class func color(withHexColor hexStr:String)->NSColor {
        var hexColorString = hexStr.trimmingCharacters(in: .whitespacesAndNewlines).uppercased()
        
        if hexColorString.hasPrefix("#") {
            hexColorString.remove(at: hexColorString.startIndex)
        }
        
        if hexColorString.count != 6 {
            NSException.raise(NSExceptionName(rawValue: "convertHexStringToColor Exception"), format: "Error: Invalid hex color string. Please ensure hex color string has 6 elements. Common error: Hashtag symbol is also included as part of the hex color string, that is not required. Ex. #4286f4 should be 4286f4", arguments: getVaList(["nil"]))
        }
        var hexColorRGBValue:UInt32 = 0
        Scanner(string: hexColorString).scanHexInt32(&hexColorRGBValue)
        
        return self.color(withHex: hexColorRGBValue, 1)
    }
    
    class func color(withHex hex:UInt32, _ alpha:CGFloat)->NSColor {
        return NSColor(deviceRed:CGFloat((hex & 0xFF0000) >> 16)/255.0,
                green: CGFloat((hex & 0xFF00) >> 8)/255.0,
                blue: CGFloat((hex & 0xFF))/255.0,
                alpha: alpha)
    }
}

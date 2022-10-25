//
//  Tools.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/1/11.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation

//john.tyler

func YMLog<T>(_ msg: T, file: String = #file, function: String = #function, line: Int = #line) {
    
    #if DEBUG
        let fileName = (file as NSString).lastPathComponent
        print("\(fileName) Line:\(line) \(function) | \(msg)")
    #endif
}

func RGBA(r: CGFloat, g: CGFloat, b: CGFloat, a: CGFloat) -> NSColor {
    return NSColor.init(red: r*1.0/255.0, green: g*1.0/255.0, blue: b*1.0/255.0, alpha: a*1.0)
}

func RGB(r: CGFloat, g: CGFloat, b: CGFloat) -> NSColor {
    return RGBA(r: r, g: g, b: b, a: 1.0)
}


/// Gets the display size based on the text content length and font size
///
/// - Parameters:
///   - string: string
///   - font: font
///   - maxSize: max size
/// - Returns: size



func getStringSizeWithFont(string: String, font: NSFont, maxSize: NSSize) -> NSSize {
//    NSSize(width: 30, height: CGFloat.greatestFiniteMagnitude)
    let str = string as NSString
    let  attr = [NSAttributedString.Key.font: font];
    return str.boundingRect(with: maxSize, options: NSString.DrawingOptions.usesLineFragmentOrigin, attributes: attr).size
}




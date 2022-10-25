//
//  NXConstant.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 26/06/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

/// Constant value in global.
struct NXConstant {
    static let kTitle = "SkyDRM Desktop".localized
    
    // Use to control theme.
    struct NXColor {
        static let linear = ("#6AB3FA", "#087FFF")
        
    }
    
}
extension NSPasteboard.PasteboardType {
    static let backwarfsCompatibleURL:NSPasteboard.PasteboardType = {
        if #available(OSX 10.13, *) {
            return NSPasteboard.PasteboardType.URL
        } else {
            return NSPasteboard.PasteboardType(kUTTypeURL as String)
        }
    }()
}

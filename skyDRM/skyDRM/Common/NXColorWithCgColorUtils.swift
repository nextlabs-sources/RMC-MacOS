//
//  NXColorWithCgColorUtils.swift
//  skyDRM
//
//  Created by William (Weiyan) Zhao on 2018/12/18.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Cocoa
extension CALayer {
    var backgroundColorWithNSColor:NSColor {
        set {
            self.backgroundColor = newValue.cgColor
        }
        get {
            if self.backgroundColor == nil {
                return NSColor()
            } else {
                return NSColor(cgColor: self.backgroundColor!)!
            }
        }
    }
}


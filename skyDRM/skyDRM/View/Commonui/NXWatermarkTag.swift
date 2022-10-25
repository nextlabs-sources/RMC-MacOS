//
//  NXWatermarkTag.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 23/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

enum NXWatermarkTag: Int, CaseIterable {
    case Date = 0
    case Time = 1
    case Email = 2
    case LineBreak = 3
    
    func getImage() -> NSImage {
        switch self {
        case .Date:
            return NSImage(named:"watermark_date")!
        case .Time:
            return NSImage(named: "watermark_time")!
        case .Email:
            return NSImage(named:  "watermark_email")!
        case .LineBreak:
            return NSImage(named:  "watermark_linebreak")!
        }
    }
    
    func getSize() -> NSSize {
        switch self {
        case .Date:
            return NSMakeSize(55, 20)
        case .Time:
            return NSMakeSize(55, 20)
        case .Email:
            return NSMakeSize(71, 20)
        case .LineBreak:
            return NSMakeSize(74, 20)
        }
    }
    
    func getAttributeKey() -> String {
        switch self {
        case .Date:
            return "Attr_Date_Key"
        case .Email:
            return "Attr_Email_Key"
        case .Time:
            return "Attr_Time_Key"
        case .LineBreak:
            return "Attr_LineBreak_Key"
        }
    }
    func rmsShortcut() -> String {
        switch self {
        case .Date:
            return "$(Date)"
        case .Email:
            return "$(User)"
        case .Time:
            return "$(Time)"
        case .LineBreak:
            return "$(Break)"
        }
    }
    static func create(keys: [String:Any]) -> NXWatermarkTag? {
        var nxWatermarkTag:NXWatermarkTag?
        var waterMarkTag =  [NXWatermarkTag]()
        for ( key, _ ) in keys {
            if key.contains("Attr_Date_Key") {
                waterMarkTag.append(.Date)
            }
            else if key.contains("Attr_Email_Key") {
                waterMarkTag.append(.Email)
            }
            else if key.contains("Attr_Time_Key") {
                waterMarkTag.append(.Time)
            }
            else if key.contains("Attr_LineBreak_Key") {
                waterMarkTag.append(.LineBreak)
            }
        }
        for k in waterMarkTag {
            nxWatermarkTag = k
        }
        return nxWatermarkTag
    }
    
    func getButtonId() -> String {
        switch self {
        case .Date:
            return "Button_Id_Date"
        case .Email:
            return "Button_Id_Email"
        case .Time:
            return "Button_Id_Time"
        case .LineBreak:
            return "Button_Id_LineBreak"
        }
    }
    
    static func create(buttonId: String) -> NXWatermarkTag? {
        if buttonId == "Button_Id_Date" {
            return .Date
        }
        else if buttonId == "Button_Id_Email" {
            return .Email
        }
        else if buttonId == "Button_Id_Time" {
            return .Time
        }
        else if buttonId == "Button_Id_LineBreak" {
            return .LineBreak
        }
        else {
            return nil
        }
    }
    
    func charaterNumber() -> Int {
        switch self {
        case .Date:
            return 7
        case .Email:
            return 7
        case .Time:
            return 7
        case .LineBreak:
            return 8
        }
    }
}

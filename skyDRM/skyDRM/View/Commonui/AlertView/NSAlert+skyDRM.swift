//
//  NSAlert+skyDRM.swift
//  skyDRM
//
//  Created by bill.zhang on 3/10/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

enum NXAlertReturnButtonType {
    case cancel
    case sure
    case other
}

typealias AlertClosure = (_ selectIndex:NXAlertReturnButtonType) -> Void

extension NSAlert {
    
    static func showAlert(withMessage message:String, informativeText:String = "", dismissClosure: AlertClosure? = nil){
        
        
        DispatchQueue.main.async {
            let alert = NSAlert()
            
            alert.window.backgroundColor = NSColor.white
            alert.alertStyle = .warning
            alert.window.title = NSLocalizedString("APP_NAME", comment: "")
            alert.icon = NSImage(named:  "protectDataIcon")
            alert.messageText = message
            alert.informativeText = informativeText
            
            alert.addButton(withTitle: NSLocalizedString("OK", comment: "")).keyEquivalent = "\r"
            let res = alert.runModal()
            if NSApplication.ModalResponse.alertFirstButtonReturn == res {
                dismissClosure?(.sure)
            }
        }
    }
    
    static func showAlert(withMessage message:String, confirmButtonTitle:String, cancelButtonTitle:String, defaultCancelButton:Bool = false, titleName:String = "", dismissClosure:@escaping AlertClosure){
        DispatchQueue.main.async {
            let alert = NSAlert()
            
            alert.window.backgroundColor = NSColor.white
            alert.alertStyle = .warning
            if titleName == "" {
                alert.window.title = NSLocalizedString("APP_NAME", comment: "")
            }else{
                alert.window.title = titleName
            }
            alert.icon = NSImage(named:"protectDataIcon")
            
            alert.messageText = message
            
            if defaultCancelButton {
                alert.addButton(withTitle: confirmButtonTitle).keyEquivalent = "\u{1b}"
                alert.addButton(withTitle: cancelButtonTitle).keyEquivalent = "\r"
            } else {
                alert.addButton(withTitle: confirmButtonTitle).keyEquivalent = "\r"
                alert.addButton(withTitle: cancelButtonTitle).keyEquivalent = "\u{1b}"
            }
            
            let res = alert.runModal()
            
            if NSApplication.ModalResponse.alertFirstButtonReturn == res {
                dismissClosure(.sure)
            }
            
            if NSApplication.ModalResponse.alertSecondButtonReturn == res {
                dismissClosure(.cancel)
            }
        }
    }
    
    static func show(with title: String?, message: String, cancelTitle: String, confirmTitle: String, otherTitle: String? = nil, dismissHandler: @escaping AlertClosure) {
        DispatchQueue.main.async {
            let alert = NSAlert()
            alert.window.backgroundColor = NSColor.white
            alert.alertStyle = .warning
            if let title = title {
                alert.window.title = title
            } else {
                alert.window.title = NSLocalizedString("APP_NAME", comment: "")
            }
            alert.icon = NSImage(named:"protectDataIcon")
            alert.messageText = message
            alert.addButton(withTitle: confirmTitle)
            alert.addButton(withTitle: cancelTitle)
            if let otherTitle = otherTitle {
                alert.addButton(withTitle: otherTitle)
            }
            
            let response = alert.runModal()
            var type: NXAlertReturnButtonType
            if NSApplication.ModalResponse.alertFirstButtonReturn == response {
                type = .sure
            } else if NSApplication.ModalResponse.alertSecondButtonReturn == response {
                type = .cancel
            } else {
                type = .other
            }
            
            dismissHandler(type)
        }
    }
}

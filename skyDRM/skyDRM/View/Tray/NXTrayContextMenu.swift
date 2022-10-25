//
//  NXTrayContextMenu.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 06/12/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

protocol NXTrayContextMenuDelegate: NSObjectProtocol {
    func onAbout()
    func onHelp()
    func onPreferences()
    func onFeedback()
    func onLogout()
}

class NXTrayContextMenu: NSMenu {
    private enum NXTrayMenuItemType: Int {
        case about = 0
        case help
        case feedback
        case preferences
        case logout
        
        func descprition() -> String {
            switch self {
            case .about:
                return "MENU_ITEAM_ABOUT_BUTTON".localized
            case .help:
                return "MENU_ITEAM_HELP_BUTTON".localized
            case .feedback:
                return "Send Feedback"
            case .preferences:
                return "MENU_ITEAM_PREFERENCES".localized
            case .logout:
                return "MENU_ITEAM_LOGOUT_BUTTON".localized
            }
        }
    }
    private let types: [NXTrayMenuItemType] = [.about, .help, .preferences, .logout]
    
    weak var actionDelegate: NXTrayContextMenuDelegate?
    func initCommonControl() {
        for type in types {
            let item = NSMenuItem(title: type.descprition(), action: #selector(menuItemClicked), keyEquivalent: "")
            item.tag = type.rawValue
            item.target = self
            addItem(item)
        }
    }
    @objc public func menuItemClicked(sender: NSMenuItem) {
        guard let action = NXTrayMenuItemType(rawValue: sender.tag) else {
            return
        }
        switch action {
        case .about:
            actionDelegate?.onAbout()
        case .help:
            actionDelegate?.onHelp()
        case .feedback:
            actionDelegate?.onFeedback()
        case .preferences:
            actionDelegate?.onPreferences()
        case .logout:
            actionDelegate?.onLogout()
        }
    }
    
}

extension NXTrayContextMenu: NSUserInterfaceValidations {
    func validateUserInterfaceItem(_ item: NSValidatedUserInterfaceItem) -> Bool {
        if item.tag == NXTrayMenuItemType.logout.rawValue {
            if let mainVC = NSApp.mainWindow?.contentViewController as? NXLocalMainViewController, mainVC.isLoading {
                return false
            }
        }
        
        return true
    }
}

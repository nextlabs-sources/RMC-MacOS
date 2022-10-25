//
//  AppDelegate+Menu.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/8.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa


enum NXMainMenu: Int {
    case skyDrm = 0
    case file
    case view
    case manage
    case project
    case window
    case help
    
    var menuItem: NSMenuItem? {
        return NSApp.mainMenu?.item(at: rawValue)
    }
    var submenu: NSMenu? {
        return NSApp.mainMenu?.item(at: rawValue)?.submenu
    }
}
enum NXSkyDrmMenu: Int {
    case about = 0
    case exit = 2
    var menuItem: NSMenuItem? {
        let skyDrmMenu: NXMainMenu = .skyDrm
        return skyDrmMenu.submenu?.item(at: rawValue)
    }
    var submenu: NSMenu? {
        let skyDrmMenu: NXMainMenu = .skyDrm
        return skyDrmMenu.submenu?.item(at: rawValue)?.submenu
    }
}
enum NXFileMenu: Int {
    case open = 0
    case protect
    case share
    case delete
    case stopUpload = 5
    case upload
    case info = 8
    case log
    case signout = 11
    
    var menuItem: NSMenuItem? {
        let fileMenu: NXMainMenu = .file
        return fileMenu.submenu?.item(at: rawValue)
    }
    var submenu: NSMenu? {
        let fileMenu: NXMainMenu = .file
        return fileMenu.submenu?.item(at: rawValue)?.submenu
    }
}

enum NXViewMenu: Int {
    case previous = 0
    case next
    case refresh = 3
    case sortby = 5
    case mydrive = 7
    case myvault
    case gotohome = 10
    
    var menuItem: NSMenuItem? {
        let viewMenu: NXMainMenu = .view
        return viewMenu.submenu?.item(at: rawValue)
    }
    var submenu: NSMenu? {
        let viewMenu: NXMainMenu = .view
        return viewMenu.submenu?.item(at: rawValue)?.submenu
    }
}

enum NXSortbyMenu: Int {
    case fileName = 0
    case lastmodified
    case fileSize
    
    var menuItem: NSMenuItem? {
        let sortbyMenu: NXViewMenu = .sortby
        return sortbyMenu.submenu?.item(at: rawValue)
    }
    var submenu: NSMenu? {
        let sortbyMenu: NXViewMenu = .sortby
        return sortbyMenu.submenu?.item(at: rawValue)?.submenu
    }
}

enum NXManageMenu: Int {
    case search = 0
    case addRepository = 2
    case repositories = 3
    case localFile = 5
    case profile = 7
    case account
    case usage = 10
    case preferences
    
    var menuItem: NSMenuItem? {
        let manageMenu: NXMainMenu = .manage
        return manageMenu.submenu?.item(at: rawValue)
    }
    var submenu: NSMenu? {
        let manageMenu: NXMainMenu = .manage
        return manageMenu.submenu?.item(at: rawValue)?.submenu
    }
}

enum NXRepositoryMenu: Int {
    case viewfiles = 0
    case rename
    case remove = 3
}

enum NXProjectMenu: Int {
    case goto = 0
    case create
    case invite = 3
    case addfile
    case manage = 6
    
    var menuItem: NSMenuItem? {
        let projectMenu: NXMainMenu = .project
        return projectMenu.submenu?.item(at: rawValue)
    }
    var submenu: NSMenu? {
        let projectMenu: NXMainMenu = .project
        return projectMenu.submenu?.item(at: rawValue)?.submenu
    }
}

enum NXHelpMenu: Int {
    case gettingStarted = 0
    case help
    case update = 3
    case report
    
    var menuItem: NSMenuItem? {
        let helpMenu: NXMainMenu = .help
        return helpMenu.submenu?.item(at: rawValue)
    }
    var submenu: NSMenu? {
        let helpMenu: NXMainMenu = .help
        return helpMenu.submenu?.item(at: rawValue)?.submenu
    }
}

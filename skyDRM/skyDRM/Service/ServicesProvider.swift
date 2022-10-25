//
//  ServicesProvider.swift
//  ServicesDemo
//
//  Created by Paul (Qian) Chen on 19/04/2017.
//  Copyright © 2017 CQ. All rights reserved.
//

import Cocoa
import FinderSync

@objcMembers class ServicesProvider: NSObject {
    enum ServicesType {
        case openFile
        case protectFile
        case shareFile
        case addFileToProject
        case openMain
        case openWeb
    }
    
    fileprivate struct Constant {
        // Display message
        static let shareFolderWarningMessage = NSLocalizedString("VIEW_CONTROLLER_INVALID_OPERATION", comment: "")
        static let protectWarningMessage = "SERVICES_INVALID_OPERATION_FOR_NXL_FILE".localized
        static let addFileToProjectFileTypeWarning = "SERVICES_INVALID_OPERATION_FOR_NORMAL_FILE".localized
        static let addFileToProjectMultipleWarning = "SERVICES_INVALID_OPERATION_FOR_MULTIPLE_FILE".localized
        
    }
    
    // MARK: Service Operations.
    func serviceOperations(_ pasteboard:NSPasteboard,userData:String?,error:AutoreleasingUnsafeMutablePointer<NSString>) -> Void {
        if userData == "shareFile" {
            if let paths = getFilePath(from: pasteboard) {
                handle(type: .shareFile, paths: paths)
            }
        } else if userData == "protectFile" {
           if let paths = getFilePath(from: pasteboard) {
                handle(type: .protectFile, paths: paths)
            }

        } else if userData == "addFileToProject" {
            if let paths = getFilePath(from: pasteboard) {
                handle(type: .addFileToProject, paths: paths)
            }
        } else if userData == "openMain" {
            handle(type: .openMain, paths: [])
        } else if userData == "openWeb" {
            handle(type: .openWeb, paths: [])
        }
    }
    
    func handle(type: ServicesType, paths: [String]) {
        switch type {
        case .openMain:
            openMain()
        case .openWeb:
            openWeb()
        case .openFile,
             .protectFile,
             .shareFile,
             .addFileToProject:
            
            if !NXWindowsManager.sharedInstance.isMainWindowLoaded {
                if type == .openFile, let delegate = NSApp.delegate as? AppDelegate, delegate.didFinish == false {
                    return
                }
                
                openMain()
                return
            }
            
            if checkHasFolder(paths: paths) {
                NSAlert.showAlert(withMessage: Constant.shareFolderWarningMessage)
                return
            }
            
            if type == .openFile {
                openFile(with: paths)
            } else if type == .protectFile || type == .shareFile {
                if checkHasNXLFile(paths: paths) {
                    NSAlert.showAlert(withMessage: Constant.protectWarningMessage)
                    return
                }
                
                if type == .protectFile {
                    protect(with: paths)
                } else {
                    share(with: paths)
                }
                
            } else if type == .addFileToProject {
                guard paths.count == 1, let path = paths.first else {
                    NSAlert.showAlert(withMessage: Constant.addFileToProjectMultipleWarning)
                    return
                }
                
                if !NXCommonUtils.isNXLFile(path: path) {
                    NSAlert.showAlert(withMessage: Constant.addFileToProjectFileTypeWarning)
                    return
                }
                
                addFileToProject(paths: paths)
            }
            
        }
    }
}

extension ServicesProvider {
    func openFile(with paths: [String]) {
        for path in paths {
            NXFileRenderManager.shared.viewLocal(path: path)
        }
    }
    
    func protect(with paths: [String]) {
        encypt(type: .protectFile, paths: paths, tags: nil)
    }
    
    func share(with paths: [String]) {
        encypt(type: .shareFile, paths: paths, tags: nil)
    }
    
    func openWeb() {
        if NXClient.getCurrentClient().isLogin() {
            NXCommonUtils.openWebsite()
        } else {
            openMain()
        }
    }
    
    func openMain() {
        if NXWindowsManager.sharedInstance.isMainWindowHasContent {
            NXWindowsManager.sharedInstance.showMainWindow()
        } else {
            NXWindowsManager.sharedInstance.showTray()
        }
    }
    
    func addFileToProject(paths: [String]) {
        self.encypt(type: .addFileToProject, paths: paths, tags: nil)
    }
    
    func getFileWhetherTagFile(path: String, completion: @escaping (_ canAdd: Bool) -> ()) {
        completion(false)
    }
}

extension ServicesProvider {
    func encypt(type: PendingTaskType, paths: [String], tags: [String: [String]]?) {
        
        let urls = paths.map() { URL.init(fileURLWithPath: $0) }
        
        NXWindowsManager.sharedInstance.showMainWindow()
        
        if let vc = NXWindowsManager.sharedInstance.mainWindow.contentViewController as? NXLocalMainViewController {
            if type == .protectFile {
                vc.protectFile(urls: urls)
            } else if type == .shareFile {
                vc.shareFile(urls: urls)
            } else if type == .addFileToProject {
                vc.addFileToProjectWith(path: paths.first ?? "", tags: tags ?? [:])
            }
        }
    }
}

extension ServicesProvider {
    fileprivate func getFilePath(from pasteboard: NSPasteboard) -> [String]? {
    guard let paths = pasteboard.propertyList(forType:NSPasteboard.PasteboardType("NSFilenamesPboardType")) as? [String] else { return nil }
            return paths
    }
    
    /// filter foldre only left file path
    fileprivate func filterFile(from paths: [String]) -> [String] {
        var filterPaths = [String]()
        for item in paths {
            let attr = try? FileManager.default.attributesOfItem(atPath: item)
            if let type = attr?[FileAttributeKey.type] as? FileAttributeType,
                type == .typeRegular {
                filterPaths.append(item)
            }
        }
        
        return filterPaths
    }
    
    fileprivate func isFolderPath(with path: String) -> Bool {
        let attr = try? FileManager.default.attributesOfItem(atPath: path)
        if let type = attr?[FileAttributeKey.type] as? FileAttributeType,
            type == .typeDirectory {
            return true
        }
        
        return false
    }
    fileprivate func showLoginView() {
        NSApp.activate(ignoringOtherApps: true)
        NXWindowsManager.sharedInstance.showMainWindow()
        NXWindowsManager.sharedInstance.showTray()
        
    }
    
    private func checkHasFolder(paths: [String]) -> Bool {
        for path in paths {
            if isFolder(path: path) {
                return true
            }
        }
        
        return false
    }
    
    private func checkHasNXLFile(paths: [String]) -> Bool {
        for path in paths {
            if NXCommonUtils.isNXLFile(path: path) {
                return true
            }
        }
        
        return false
    }
    
    private func isFolder(path: String) -> Bool {
        let attr = try? FileManager.default.attributesOfItem(atPath: path)
        if let type = attr?[FileAttributeKey.type] as? FileAttributeType,
            type == .typeDirectory {
            return true
        }
        
        return false
    }
}

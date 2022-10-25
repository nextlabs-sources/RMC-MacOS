//
//  NXFileRenderCommon.swift
//  skyDRM
//
//  Created by helpdesk on 4/10/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation
import SDML

class NXFileRenderManager : NSObject{
    static let shared = NXFileRenderManager()
    private override init() {
        super.init()
        NotificationCenter.add(self, selector: #selector(observeNotification(_:)), notification: .logout, object: nil)
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    @objc func observeNotification(_ notification: Notification) {
        if notification.nxNotification == .logout {
            closeAllFile()
        }
    }
    
    fileprivate var fileRenderWindows = [String: NSWindowController]()
    
    func viewLocal(path: String) {
        let file: NXFileBase
        if NXCommonUtils.isNXLFile(path: path) {
            file = NXNXLFile()
        } else {
            file = NXFileBase()
        }
        
        file.localPath = path
        file.name = URL(fileURLWithPath: path).lastPathComponent
        
        do {
            let attributes = try FileManager.default.attributesOfItem(atPath: path)
            if let size = attributes[FileAttributeKey.size] as? Int {
                file.size = Int64(size)
            }
        } catch {
            print(error)
        }
        
        viewFile(item: file, renderEventSrc: .local)
    }
    
    func viewCache(file: NXFileBase) {
        file.fileStatus.insert(.opened)
        self.viewFile(item: file, renderEventSrc: .cache)
    }
    
    // Private methods.
    func viewFile(item: NXFileBase, renderEventSrc: NXCommonUtils.renderEventSrcType){
        let key = getKey(item: item, renderEventSrc: renderEventSrc)
        
        if let windowController = fileRenderWindows[key] {
            windowController.window?.makeKeyAndOrderFront(nil)
        } else {
            var renderFileWindowController: NXFileRenderWindowController?
            switch NXFileRenderSupportUtil.renderFileType(fileName: item.name) {
            case .NORMAL,
                 .REMOTEVIEW:
                let windowController = NXNormalFileRenderWindowController.loadFromNib()
                windowController.delegate = self
                windowController.initToolbarItem(fileItem: item)
                renderFileWindowController = windowController
                
            case .HPS3D:
                let windowController = NXHPSFileRenderWindowController.loadFromNib()
                windowController.delegate = self
                windowController.initToolbarItem(fileItem: item)
                renderFileWindowController = windowController
                
            case .NOT_SUPPORT:
                let warningMessage = "PROJECT_FILES_RENDER_FAILED".localized
                NSAlert.showAlert(withMessage: warningMessage)
                item.fileStatus.remove(.opened)
                
            default:
                break
            }
            
            if let render = renderFileWindowController {
                render.window?.makeKeyAndOrderFront(nil)
                fileRenderWindows[key] = render
                render.window?.title = item.name
                
                render.commonInit(fileItem: item, renderEventSrcType: renderEventSrc)
            }
        }
        
    }
    
    func closeAllFile() {
        for item in fileRenderWindows {
            item.value.close()
        }
    }
    
    private func getKey(item: NXFileBase, renderEventSrc: NXCommonUtils.renderEventSrcType) -> String {
        let key: String
        if renderEventSrc == .cache {
            key = item.getNXLID()!
        } else {
            key = item.localPath
        }
        
        return key
    }
}

extension NXFileRenderManager: NXRenderWindowControllerDelegate {
    func close(windowController: NSWindowController) {
        
        guard let wc = windowController as? NXFileRenderWindowController else {
            return
        }
        
        if !wc.isSwitch {
            // Remove key.
            
            if let item = wc.fileItem, let renderEventSrc = wc.renderEventSrcType {
                let key = getKey(item: item, renderEventSrc: renderEventSrc)
                fileRenderWindows.removeValue(forKey: key)
            }
            
            wc.fileItem?.fileStatus.remove(.opened)
            
            if let _ = wc.fileItem?.sdmlBaseFile as? SDMLOutBoxFile {
                NotificationCenter.post(notification: .renderFinish, object: wc.fileItem!)
            }
        
            wc.nxRenderProxy.cancel()
        }
        
    }
    
    func switch3D(oldController: NXFileRenderWindowController) {
        let item = oldController.fileItem!
        let renderEventSrc = oldController.renderEventSrcType!
        
        let newController = NXHPSFileRenderWindowController.loadFromNib()
        newController.delegate = self
        
        // Remove old window.
        oldController.window?.close()
        // Show new window.
        newController.window?.makeKeyAndOrderFront(nil)
        
        let key = getKey(item: item, renderEventSrc: renderEventSrc)
        fileRenderWindows[key] = newController
        newController.window?.title = item.name
        
        newController.commonInit(fileItem: item, renderEventSrcType: renderEventSrc, decryptProxy: oldController.nxRenderProxy)
        
        
    }
}

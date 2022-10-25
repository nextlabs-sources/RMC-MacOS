//
//  NXTrayManager.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 31/10/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXTrayManager: NSObject {
    
    private var eventMonitor: NXEventMonitor?
    private let popover = NSPopover()
    private var statusItem: NSStatusItem?
    public func setup() {
        popover.appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
        statusItem = NSStatusBar.system.statusItem(withLength: -1)
        if let button = statusItem?.button {
            button.image = NSImage(named: "trayicon")
           //button.image?.isTemplate = true
            button.target = self
            button.action = #selector(NXTrayManager.togglePopover(_:))
        }
        
        popover.animates = true
        
        let popoverVC = NXTrayViewController(nibName: "NXTrayViewController", bundle: nil)
        popoverVC.delegate = self
        popover.contentViewController = popoverVC
        
        eventMonitor = NXEventMonitor(mask: [NSEvent.EventTypeMask.leftMouseDown , NSEvent.EventTypeMask.rightMouseDown], handler: { [weak self] event in
            if let strongSelf = self, strongSelf.popover.isShown {
                strongSelf.closePopover(event)
            }
        }) { [weak self] event -> NSEvent? in
            if let strongSelf = self,
                strongSelf.popover.isShown,
                event.windowNumber != strongSelf.popover.contentViewController?.view.window?.windowNumber {
                strongSelf.closePopover(event)
                return nil
            } else {
                return event
            }
        }
    }
    
    func showPopover(_ sender: AnyObject?) {
        if popover.isShown {
            return
        }
        if let button = statusItem?.button {
            popover.show(relativeTo: button.bounds, of: button, preferredEdge: NSRectEdge.minY)
        }
        eventMonitor?.start()
    }
    
    func closePopover(_ sender: AnyObject?) {
        if popover.isShown == false {
            return
        }
        popover.performClose(sender)
        eventMonitor?.stop()
    }
    
    
    @objc func togglePopover(_ sender: AnyObject?) {
        if popover.isShown {
            closePopover(sender)
        } else {
            showPopover(sender)
        }
    }
}

extension NXTrayManager: NXTrayViewControllerDelegate {
    func closePopover() {
        closePopover(nil)
    }
    func showPopover() {
        showPopover(nil)
    }
    
    func setUpPopoverAppearanceToVibrantLight(flag:Bool)
    {
        if flag == true {
                YMLog("vibrantLight!!!!!")
              popover.appearance = NSAppearance(named: NSAppearance.Name.vibrantLight)
        }else{
            YMLog("aqua!!!!!")
            popover.appearance = NSAppearance(named: NSAppearance.Name.aqua)
        }
    }
}

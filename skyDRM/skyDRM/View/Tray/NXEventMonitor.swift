//
//  NXEventMonitor.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 31/10/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation
public class NXEventMonitor {
    private var monitor: AnyObject?
    private let mask: NSEvent.EventTypeMask
    private let handler: (NSEvent?) -> ()
    
    private var monitor2: Any?
    private let localHandler: (NSEvent) -> NSEvent?
    
    public init(mask: NSEvent.EventTypeMask, handler: @escaping (NSEvent?) -> (), localHandler: @escaping (NSEvent) -> NSEvent?) {
        self.mask = mask
        self.handler = handler
        self.localHandler = localHandler
    }
    
    deinit {
        stop()
    }
    
    public func start() {
        monitor = NSEvent.addGlobalMonitorForEvents(matching: mask, handler: handler) as AnyObject?
        monitor2 = NSEvent.addLocalMonitorForEvents(matching: mask, handler: localHandler)
    }
    
    public func stop() {
        if monitor != nil, monitor2 != nil {
            NSEvent.removeMonitor(monitor!)
            NSEvent.removeMonitor(monitor2!)
            monitor = nil
            monitor2 = nil
        }
    }
}

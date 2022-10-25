//
//  NXSkyDrmMenuAction.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 05/06/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXSkyDrmMenuAction: NSObject {
    static let shared = NXSkyDrmMenuAction()
    override private init() {
        super.init()
    }
   @objc func about() {
        NXHelpPageWindowController.shared.showWindow()
    }
}

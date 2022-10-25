//
//  NXSpecificProjectData.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 21/08/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXSpecificProjectData: NSObject {
    static let shared = NXSpecificProjectData()
    private override init() {
        super.init()
    }
    @objc private dynamic var projectInfo = NXProject()
    private let lock = NSLock()
    func setProjectInfo(info: NXProject) {
        lock.lock()
        self.projectInfo = info
        lock.unlock()
    }
    func getProjectInfo() -> NXProject {
        return projectInfo
    }
}

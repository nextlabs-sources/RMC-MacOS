//
//  NXDebug.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 2018/10/17.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

class NXDebug {
    static func print<Subject>(instance: Subject, functionName: String, addition: String) {
        debugPrint("\(Date())-\(Thread.current)-\(String(describing: instance))-\(functionName)-\(addition)")
    }
}

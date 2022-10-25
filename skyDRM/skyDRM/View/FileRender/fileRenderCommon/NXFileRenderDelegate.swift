//
//  NXFileRenderDelegate.swift
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 4/14/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol NXFileRenderDelegate: NSObjectProtocol {
    func startParse()
    func parseFileFinish(path: String, error: NSError?)
}

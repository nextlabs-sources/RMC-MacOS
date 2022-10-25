//
//  HoverTableRowDelegate.swift
//  skyDRM
//
//  Created by Kevin on 2017/2/9.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

protocol HoverTableRowDelegate: NSObjectProtocol {
    func HoverTableRowEnter(row: Int)
    func HoverTableRowExit(row: Int)
}

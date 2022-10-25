//
//  NXAccountVCResponseDelegate.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/24.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

protocol NXAccountVCDelegate: NSObjectProtocol {
    func onAccountVCClose()
    func onAccountLogout()
    func onAccountAvatar()
    func onAccountName()
}

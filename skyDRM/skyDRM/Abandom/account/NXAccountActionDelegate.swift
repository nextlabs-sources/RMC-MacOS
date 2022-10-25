//
//  NXAccountActionDelegate.swift
//  skyDRM
//
//  Created by nextlabs on 16/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol NXAccountActionDelegate: NSObjectProtocol {
    func accountLogout()
    func accountCloseLogoutView()
    func accountChangeAvatar()
    func accountChangeName()
    func accountOpenManageView()
    func accountOpenChangeView()
    func accountGobackFromChangeView()
    func accountCloseChangeView()
    func accountGobackFromManageView()
    func accountCloseManageView()
}

//
//  NXHomeViewDelegate.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/24.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

protocol NXHomeViewDelegate:NSObjectProtocol {
    func homeOpenRepositoryVC()
    func homeGotoMySpace(type: RepoNavItem, alias: String)
    func homeRefreshAvatar()
    func homeOpenProject()
    func homeOpenAccountVC()
    func homeOpenProjectActivate()
}

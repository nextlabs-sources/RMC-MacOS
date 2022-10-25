//
//  NXConnectedRepoVCDelegate.swift
//  skyDRM
//
//  Created by nextlabs on 2017/2/23.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation
protocol NXRepositoryActionDelegate: NSObjectProtocol {
    func closeConnectedView()
    func closeAddView()
    func closeManageView()
    func openAddView()
    func openManageView(currentRepo: NXRMCRepoItem,AllRepo:[NXRMCRepoItem])
    func gobackFromAddView()
    func gobackFromManageView()
    func update()
    func disconnect()
    func connect()
}

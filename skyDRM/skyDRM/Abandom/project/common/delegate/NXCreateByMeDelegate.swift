//
//  NXCreateByMeDelegate.swift
//  skyDRM
//
//  Created by helpdesk on 2/20/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol NXCreateByMeDelegate:NSObjectProtocol {
    func onInviteClick(projectInfo: NXProject)
    
    func onItemClick(projectInfo: NXProject)
}

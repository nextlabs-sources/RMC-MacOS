//
//  NXProjectInviteDelegate.swift
//  skyDRM
//
//  Created by helpdesk on 3/6/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol NXProjectInviteDelegate:NSObjectProtocol {
    func onInvite(projectId: String, emailArray: [String], invitationMsg: String)
}

//
//  NXNewProjectDelegate.swift
//  skyDRM
//
//  Created by helpdesk on 2/23/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol NXNewProjectDelegate:NSObjectProtocol {
    func onNewProject(title: String, description: String, emailArray: [String], invitationMsg: String)
}

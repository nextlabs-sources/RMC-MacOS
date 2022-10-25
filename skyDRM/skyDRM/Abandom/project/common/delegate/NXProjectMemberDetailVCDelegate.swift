//
//  NXProjectMemberDetailVCDelegate.swift
//  skyDRM
//
//  Created by xx-huang on 06/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol NXProjectMemberDetailVCDelegate : NSObjectProtocol {
    func removeMemberFromProjectFinished(error:Error?, member: NXProjectMember)
}

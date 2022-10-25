//
//  NXProjectInvitationModel.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/3/14.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation


class NXProjectInvitationModel: NSObject {
    var       invitationId: String?
    var       inviteeEmail: String?
    var       inviterEmail: String?
    var inviterDisplayName: String?
    var         inviteTime: TimeInterval?
    var            project: NXProjectModel?
    
    override init() {
        super.init()
    }
}

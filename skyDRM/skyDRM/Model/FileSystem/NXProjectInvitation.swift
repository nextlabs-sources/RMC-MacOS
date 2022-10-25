//
//  NXProjectInvitation.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 14/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXProjectInvitation: NSObject {
    var invitationId: String?
    var inviteeEmail: String?
    var inviterEmail: String?
    var inviterDisplayName: String?
    var inviteTime: TimeInterval = 0.0
    var code: String?
    var project: NXProject?
    
    var invitationMsg: String?
    
    override var hash : Int {
        return 0
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? NXProjectInvitation,
            invitationId == object.invitationId,
            project == object.project {
            return true
        }
        
        return false
    }
}

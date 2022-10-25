//
//  NXProject.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 11/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXProject: NSObject, NSCopying {
    
    var projectId: String?
    
    var owner: NXProjectOwner?
    var creationTime: Date?
    var trialEndTime: Date?
    var accountType: NXAccountType?
    var displayName: String?
    var invitationMsg: String?
    var name: String?
    var projectDescription: String?
    var ownedByMe: Bool = true
    var totalFiles: Int = 0
    var totalMembers: Int = 0
    var extraInfo: [String: Any]?
    
    var projectInvitation: [NXProjectInvitation]?
    var projectMembers: [NXProjectMember]?
    
    func copy(with zone: NSZone? = nil) -> Any {
        let other = NXProject()
        other.projectId = projectId
        other.name = name
        other.projectDescription = projectDescription
        other.displayName = displayName
        other.creationTime = creationTime
        other.totalMembers = totalMembers
        other.totalFiles = totalFiles
        other.ownedByMe = ownedByMe
        other.owner = owner?.copy() as? NXProjectOwner
        other.accountType = accountType
        other.trialEndTime = trialEndTime
        other.projectMembers = projectMembers?.map{$0.copy() as! NXProjectMember}
        other.invitationMsg = invitationMsg
        return other
    }
    
    override var hash : Int {
        return 0
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let project = object as? NXProject,
            projectId == project.projectId {
            return true
        }
        return false
    }
}

extension NXProject {
    static func ==(lhs: NXProject, rhs: NXProject) -> Bool {
        return lhs.projectId == rhs.projectId
    }
    static func !=(lhs: NXProject, rhs: NXProject) -> Bool {
        return !(lhs.projectId == rhs.projectId)
    }
}

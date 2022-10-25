//
//  NXProjectModel.swift
//  skyDRM
//
//  Created by Ivan (Youmin) Zhang on 2019/3/14.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation
import SDML

class NXProjectModel: NSObject {
    var               name = String()
    var   parentTenantName: String?
    var     parentTenantId: String?
    var         totalFiles: Int?
    var       totalMembers: Int?
    var        displayName: String?
    var projectDescription = String()
    var tokenGroupName    : String?
    var                 id: Int?
    var          ownedByMe: Bool?
    var       creationTime: Date?
    var       trialEndTime: Date?
    var              owner: NXProjectUserInfo?
    var         invitation: [NXProjectInvitationModel]?
    var           memabers: [NXProjectMemberModel]?
    var          rootFiles = [NXSyncFile]()
    var            folders = [NXSyncFile]()
    var        tagTemplate: NXProjectTagTemplateModel?
    var        sdmlProject: SDMLProject?
    
    override init() {
        super.init()
    }
}

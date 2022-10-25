//
//  DBProjectInvitationHandler.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 14/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

// MARK: use projectId and invitationId to search invitation

class DBProjectInvitationHandler {
    fileprivate struct Constant {
        static let entityName = "ProjectInvitation"
    }
    
    static let shared = DBProjectInvitationHandler()
    private init() {}
    
    fileprivate var context: NSManagedObjectContext {
        get {
            return (NXLoginUser.sharedInstance.dataController?.managedObjectContext)!
        }
    }
    
    // TODO: filter
    func getActiveProjectInvitation(with project: NXProject, filter: NXProjectPendingInvitationFilter?) -> [NXProjectInvitation]? {
        let dbProject = DBProjectHandler.shared.fetch(with: project, isActive: true)
        if let invitationSet = dbProject?.invitation as? Set<ProjectInvitation> {
            let invitations = invitationSet.map() { DBProjectInvitationHandler.convert(from: $0, isWithRelationShip: true) }
            return invitations
        }
        
        return nil
    }
    
    func getProjectInvitationForUser() -> [NXProjectInvitation]? {
        let request = NSFetchRequest<ProjectInvitation>(entityName: Constant.entityName)
        let userEmail = (NXLoginUser.sharedInstance.nxlClient?.profile.email)!
        request.predicate = NSPredicate(format: "inviteeEmail == %@", userEmail)
        let result = DBCommonUtil.fetchResult(withContext: context, request: request)
        
        let invitations = result.map() { DBProjectInvitationHandler.convert(from: $0, isWithRelationShip: true) }
        return invitations
    }
    
    // Set
    func syncActiveInvitation(with project: NXProject, invitation: [NXProjectInvitation], isWithDelete: Bool) -> Bool {
        let olds = getActiveProjectInvitation(with: project, filter: nil)!
        let news = invitation.map() {
            invitate -> NXProjectInvitation in
            if invitate.project == nil {
                invitate.project = project
            }
            
            return invitate
        }
        let (updates, adds, deletes) = NXCommonUtils.diffChanges(olds: olds, news: news)
        
        for invitation in updates {
            _ = update(with: project, invitation: invitation)
        }
        for invitation in adds {
            _ = add(with: project, invitation: invitation, isForUser: false)
        }
        if isWithDelete {
            for invitation in deletes {
                _ = delete(with: project, invitation: invitation, isForUser: false)
            }
        }
        
        save()
        
        return true
    }
    
    func syncInvitationForUser(invitation: [NXProjectInvitation]) -> Bool {
        let olds = getProjectInvitationForUser()!
        let (updates, adds, deletes) = NXCommonUtils.diffChanges(olds: olds, news: invitation)
        
        for invitation in updates {
            _ = update(with: invitation.project!, invitation: invitation)
        }
        for invitation in adds {
            _ = add(with: invitation.project!, invitation: invitation, isForUser: true)
        }
        for invitation in deletes {
            _ = delete(with: invitation.project!, invitation: invitation, isForUser: true)
        }
        
        save()
        
        return true
    }
    
    func removeInvitationForUser(with invitation: NXProjectInvitation) -> Bool {
        guard let project = invitation.project else {
            return false
        }
        
        _ = delete(with: project, invitation: invitation, isForUser: true)
        save()
        
        return true
    }
}

extension DBProjectInvitationHandler {
    fileprivate func fetch(with project: NXProject, invitationId: String) -> ProjectInvitation? {
        let request = NSFetchRequest<ProjectInvitation>(entityName: Constant.entityName)
        request.predicate = NSPredicate(format: "invitationId == %@", invitationId)
        let result = DBCommonUtil.fetchResult(withContext: context, request: request)
        
        let filterResult = result.filter() { $0.project?.projectId == project.projectId }
        guard filterResult.count == 1, let object = filterResult.first else {
            return nil
        }
        
        return object
    }
    
    fileprivate func update(with project: NXProject, invitation: NXProjectInvitation) -> Bool {
        if let db = fetch(with: project, invitationId: invitation.invitationId!) {
            DBProjectInvitationHandler.format(from: invitation, to: db)
        }
        
        return true
    }
    
    fileprivate func add(with project: NXProject, invitation: NXProjectInvitation, isForUser: Bool) -> Bool {
        let db = ProjectInvitation(entity: NSEntityDescription.entity(forEntityName: Constant.entityName, in: context)!, insertInto: context)
        DBProjectInvitationHandler.format(from: invitation, to: db)
        
        // Add pending project
        if isForUser {
            _ = DBProjectHandler.shared.syncProject(with: [project], isWithDelete: false, isActive: false)
        }
        
        let dbProject = DBProjectHandler.shared.fetch(with: project, isActive: !isForUser)
        db.project = dbProject
        
        return true
    }
    
    fileprivate func delete(with project: NXProject, invitation: NXProjectInvitation, isForUser: Bool) -> Bool {
        if let db = fetch(with: project, invitationId: invitation.invitationId!) {
            // Delete pending project
            if isForUser {
                if let dbProject = db.project {
                    let project = DBProjectHandler.convert(from: dbProject)
                    _ = DBProjectHandler.shared.removeProject(with: project, isActive: false)
                }
            }
            
            context.delete(db)
            
            return true
        }
        
        return false
    }
    
    fileprivate func save() {
        do {
            try context.save()
        } catch {
            fatalError()
        }
    }
    
    static func format(from nxInvitation: NXProjectInvitation, to invitation: ProjectInvitation) {
        invitation.invitationId = nxInvitation.invitationId
        invitation.inviteeEmail = nxInvitation.inviteeEmail
        invitation.inviterEmail = nxInvitation.inviterEmail
        invitation.inviterDisplayName = nxInvitation.inviterDisplayName
        invitation.inviteTime = NSDate.init(timeIntervalSince1970: nxInvitation.inviteTime) as Date
        invitation.code = nxInvitation.code
        invitation.invitationMsg = nxInvitation.invitationMsg
        
    }
    
    static func convert(from invitation: ProjectInvitation, isWithRelationShip: Bool = false) -> NXProjectInvitation {
        let nxInvitation = convert(from: invitation)
        if isWithRelationShip {
            if let project = invitation.project {
                nxInvitation.project = DBProjectHandler.convert(from: project)
            }
        }
        
        return nxInvitation
    }
    
    private static func convert(from invitation: ProjectInvitation) -> NXProjectInvitation {
        let nxInvitation = NXProjectInvitation()
        nxInvitation.invitationId = invitation.invitationId
        nxInvitation.inviteeEmail = invitation.inviteeEmail
        nxInvitation.inviterEmail = invitation.inviterEmail
        nxInvitation.inviterDisplayName = invitation.inviterDisplayName
        nxInvitation.inviteTime = (invitation.inviteTime?.timeIntervalSince1970)!
        nxInvitation.code = invitation.code
        nxInvitation.invitationMsg = invitation.invitationMsg
        return nxInvitation
    }
}

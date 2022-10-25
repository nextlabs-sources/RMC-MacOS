//
//  DBProjectMemberHandler.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 14/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

// MARK: use projectId and userId to search member

class DBProjectMemberHandler {
    fileprivate struct Constant {
        static let entityName = "ProjectMember"
    }
    
    static let shared = DBProjectMemberHandler()
    private init() {}
    
    fileprivate var context: NSManagedObjectContext {
        get {
            return (NXLoginUser.sharedInstance.dataController?.managedObjectContext)!
        }
    }
    
    // TODO: filter
    func getProjectMember(with project: NXProject, filter: NXProjectMemberFilter?) -> [NXProjectMember] {
        let project = DBProjectHandler.shared.fetch(with: project, isActive: true)
        if let memberSet = project?.member as? Set<ProjectMember> {
            return memberSet.map() { DBProjectMemberHandler.convert(from: $0, isWithRelationShip: true) }
        }
        
        return []
    }
    
    func getProjectMemberDetail(with project: NXProject, member: NXProjectMember) -> NXProjectMember? {
        if let dbMember = fetch(with: project, userId: member.userId!) {
            return DBProjectMemberHandler.convert(from: dbMember, isWithRelationShip: true)
        }
        
        return nil
    }
    
    func syncMember(with project: NXProject, members: [NXProjectMember], isWithDelete: Bool) -> Bool {
        let olds = getProjectMember(with: project, filter: nil)
        let news = members.map() {
            member -> NXProjectMember in
            if member.project == nil {
                member.project = project
            }
            
            return member
        }
        let (updates, adds, deletes) = NXCommonUtils.diffChanges(olds: olds, news: news)
        
        for member in updates {
            _ = update(with: project, member: member)
        }
        for member in adds {
            _ = add(with: project, member: member)
        }
        if isWithDelete {
            for member in deletes {
                _ = delete(with: project, member: member)
            }
        }
        
        save()
        
        return true
    }
    
    func removeMember(with project: NXProject, member: NXProjectMember) -> Bool {
        _ = delete(with: project, member: member)
        save()
        
        return true
    }
}

extension DBProjectMemberHandler {
    fileprivate func fetch(with project: NXProject, userId: String) -> ProjectMember? {
        let dbProject = DBProjectHandler.shared.fetch(with: project, isActive: true)
        if let memberSet = dbProject?.member as? Set<ProjectMember> {
            let member = memberSet.filter() { $0.userId == userId }
            
            guard member.count == 1, let object = member.first else {
                return nil
            }
            
            return object
        }
        
        return nil
    }
    
    fileprivate func update(with project: NXProject, member: NXProjectMember) -> Bool {
        if let db = fetch(with: project, userId: member.userId!) {
            DBProjectMemberHandler.format(from: member, to: db)
        }
        
        return true
    }
    
    fileprivate func add(with project: NXProject, member: NXProjectMember) -> Bool {
        let db = ProjectMember(entity: NSEntityDescription.entity(forEntityName: Constant.entityName, in: context)!, insertInto: context)
        DBProjectMemberHandler.format(from: member, to: db)
        
        let dbProject = DBProjectHandler.shared.fetch(with: project, isActive: true)
        db.project = dbProject
        
        return true
    }
    
    fileprivate func delete(with project: NXProject, member: NXProjectMember) -> Bool {
        if let db = fetch(with: project, userId: member.userId!) {
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

    static func convert(from projectMember: ProjectMember, isWithRelationShip: Bool = false) -> NXProjectMember {
        let nxMember = convert(from: projectMember)
        if isWithRelationShip {
            if let project = projectMember.project {
                nxMember.project = DBProjectHandler.convert(from: project)
            }
        }
        
        return nxMember
    }
    
    private static func convert(from projectMember: ProjectMember) -> NXProjectMember {
        let nxMember = NXProjectMember()
        nxMember.userId = projectMember.userId
        nxMember.displayName = projectMember.displayName
        nxMember.email = projectMember.email
        nxMember.creationTime = (projectMember.creationTime?.timeIntervalSince1970)!
        nxMember.inviterEmail = projectMember.inviterEmail
        nxMember.inviterDisplayName = projectMember.inviterDisplayName
        nxMember.avatarBase64 = projectMember.avatarBase64
        return nxMember
    }
    
    static func format(from nxProjectMember: NXProjectMember, to projectMember: ProjectMember) {
        projectMember.userId = nxProjectMember.userId
        projectMember.displayName = nxProjectMember.displayName
        projectMember.email = nxProjectMember.email
        projectMember.creationTime = Date(timeIntervalSince1970: nxProjectMember.creationTime)
        projectMember.inviterEmail = nxProjectMember.inviterEmail
        projectMember.inviterDisplayName = nxProjectMember.inviterDisplayName
        projectMember.avatarBase64 = nxProjectMember.avatarBase64
    }
}

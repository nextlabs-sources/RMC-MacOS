//
//  DBProjectHandler.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 12/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

// MARK: use projectId as major key

class DBProjectHandler {
    fileprivate struct Constant {
        static let entityName = "Project"
    }
    static let shared = DBProjectHandler()
    init() {}
    fileprivate var context: NSManagedObjectContext {
        get {
            if let context = NXLoginUser.sharedInstance.dataController?.managedObjectContext {
                return context
            } else {
                fatalError()
            }
        }
    }

    func getAllProject(with isActive: Bool) -> [NXProject] {
        let request = NSFetchRequest<Project>(entityName: Constant.entityName)
        request.predicate = NSPredicate(format: "isActive == %@", NSNumber(value: isActive))
        let result = DBCommonUtil.fetchResult(withContext: context, request: request)
        
        let projects = result.map() { DBProjectHandler.convert(from: $0, isWithRelationShip: true) }
        return projects
        }
    
    func getActiveProject(with filter: NXListProjectFilter) -> [NXProject] {
        let request = NSFetchRequest<Project>(entityName: Constant.entityName)
        
        // Filter
        if let size = filter.size,
            let sizeNumb = Int(size) {
            request.fetchLimit = sizeNumb
        }
        
        var isOWnedByMe: Bool?
        switch filter.listProjectType {
        case .allProject:
            break
        case .ownedByUser:
            isOWnedByMe = true
        case .userJoined:
            isOWnedByMe = false
        }
        if let isOWnedByMe = isOWnedByMe {
            request.predicate = NSPredicate(format: "ownedByMe == %@ AND isActive == YES", NSNumber(value: isOWnedByMe))
        }
        
        let sortDes = filter.listProjectOrders.map() {
            sort -> NSSortDescriptor in
            var sortDescriptor: NSSortDescriptor
            switch sort {
            case .lastActionTime(let ascend):
                sortDescriptor = NSSortDescriptor(key: "creationTime", ascending: ascend)
            case .name(let ascend):
                sortDescriptor = NSSortDescriptor(key: "name", ascending: ascend, selector: #selector(NSString.localizedStandardCompare(_:)))
            }

            return sortDescriptor
        }
        
        request.sortDescriptors = sortDes
        
        let result = DBCommonUtil.fetchResult(withContext: context, request: request)
        
        let projects = result.map() { DBProjectHandler.convert(from: $0, isWithRelationShip: true) }
        return projects
    }
    
    func syncProject(with news: [NXProject], isWithDelete: Bool, isActive: Bool) -> Bool {
        
        let olds = getAllProject(with: isActive)
        let (updates, adds, deletes) = NXCommonUtils.diffChanges(olds: olds, news: news)
        
        for project in updates {
            _ = update(with: project, isActive: isActive)
        }
        for project in adds {
            _ = add(with: project, isActive: isActive)
        }
        if isWithDelete {
            for project in deletes {
                _ = delete(with: project, isActive: isActive)
            }
        }
        
        save()
        
        return true
    }
    
    func getProjectDetail(with project: NXProject) -> NXProject? {
        if let dbProject = fetch(with: project.projectId!, isActive: true) {
            return DBProjectHandler.convert(from: dbProject, isWithRelationShip: true)
        }
        
        return nil
    }
    
    func createProject(with project: NXProject) -> Bool {
        _ = add(with: project, isActive: true)
        save()
        
        return true
    }
    
    func updateProject(with project: NXProject) -> Bool {
        _ = update(with: project, isActive: true)
        save()
        return true
    }
    
    func fetch(with nxProject: NXProject, isActive: Bool) -> Project? {
        guard let projectId = nxProject.projectId else {
            return nil
        }
        
        return fetch(with: projectId, isActive: isActive)
    }
    
    func getProjectTotalNumb(with type: NXListProjectType) -> Int {
        let result = getAllProject(with: true)
        
        var totalNumb = 0
        switch type {
        case .allProject:
            totalNumb = result.count
        case .ownedByUser:
            let owned = result.filter() { $0.ownedByMe == true }
            totalNumb = owned.count
        case .userJoined:
            let joined = result.filter() { $0.ownedByMe == false }
            totalNumb = joined.count
        }
        
        return totalNumb
    }
    
    func removeProject(with project: NXProject, isActive: Bool) -> Bool {
        _ = delete(with: project, isActive: isActive)
        save()
        
        return true
    }
}

extension DBProjectHandler {
    
    fileprivate func fetch(with projectId: String, isActive: Bool) -> Project? {
        let request = NSFetchRequest<Project>(entityName: Constant.entityName)
        request.predicate = NSPredicate(format: "projectId == %@ AND isActive == %@", projectId, NSNumber(value: isActive))
        let result = DBCommonUtil.fetchResult(withContext: context, request: request)
        guard result.count == 1, let object = result.first else {
            return nil
        }
        return object
    }
    
    fileprivate func update(with project: NXProject, isActive: Bool) -> Bool {
        if let db = fetch(with: project.projectId!, isActive: isActive) {
            DBProjectHandler.shared.changeDB(from: project, to: db)
        }
        return true
    }
    
    fileprivate func add(with project: NXProject, isActive: Bool) -> Bool {
        let db = Project(entity: NSEntityDescription.entity(forEntityName: Constant.entityName, in: context)!, insertInto: context)
        DBProjectHandler.shared.changeDB(from: project, to: db)
        
        db.isActive = isActive
        
        return true
    }
    
    fileprivate func delete(with project: NXProject, isActive: Bool) -> Bool {
        if let db = fetch(with: project.projectId!, isActive: isActive) {
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
    
    fileprivate func changeDB(from nxProject: NXProject, to project: Project) {
        DBProjectHandler.format(from: nxProject, to: project)
        
        if let members = nxProject.projectMembers {
            _ = DBProjectMemberHandler.shared.syncMember(with: nxProject, members: members, isWithDelete: false)
        }
    }
    
    static func format(from nxProject: NXProject, to project: Project) {
        project.projectId = nxProject.projectId
        project.name = nxProject.name
        project.projectDescription = nxProject.projectDescription
        project.displayName = nxProject.displayName
        project.creationTime = nxProject.creationTime
        project.totalMembers = Int32(nxProject.totalMembers)
        project.totalFiles = Int32(nxProject.totalFiles)
        project.ownedByMe = nxProject.ownedByMe
        project.accountType = nxProject.accountType?.rawValue
        project.trialEndTime = nxProject.trialEndTime
        project.invitationMsg = nxProject.invitationMsg
        
        if let owner = nxProject.owner {
            project.owner = NSKeyedArchiver.archivedData(withRootObject: owner)
        }
        
        if let extraInfo = nxProject.extraInfo {
            project.ext_attr = NSKeyedArchiver.archivedData(withRootObject: extraInfo)
        }
    }
    
    static func convert(from project: Project, isWithRelationShip: Bool = false) -> NXProject {
        let nxProject = convert(from: project)
        if isWithRelationShip {
            if let member = project.member as? Set<ProjectMember> {
                nxProject.projectMembers = member.map() { DBProjectMemberHandler.convert(from: $0) }
            }
    
            if let invitation = project.invitation as? Set<ProjectInvitation> {
                nxProject.projectInvitation = invitation.map() { DBProjectInvitationHandler.convert(from: $0) }
            }
        }
        
        return nxProject
    }
    
    private static func convert(from project: Project) -> NXProject {
        let nxProject = NXProject()
        nxProject.projectId = project.projectId
        nxProject.name = project.name
        nxProject.projectDescription = project.projectDescription
        nxProject.displayName = project.displayName
        nxProject.creationTime = project.creationTime as Date?
        nxProject.totalMembers = Int(project.totalMembers)
        nxProject.totalFiles = Int(project.totalFiles)
        nxProject.ownedByMe = project.ownedByMe
        if let accountType = project.accountType {
            nxProject.accountType = NXAccountType(rawValue: accountType)
        }
        nxProject.trialEndTime = project.trialEndTime as Date?
        nxProject.invitationMsg = project.invitationMsg
        
        if let owner = project.owner as Data? {
            nxProject.owner = NSKeyedUnarchiver.unarchiveObject(with: owner) as? NXProjectOwner
        }
        
        if let ext_attr = project.ext_attr as Data? {
            nxProject.extraInfo = NSKeyedUnarchiver.unarchiveObject(with: ext_attr) as? [String: Any]
        }
        
        return nxProject
    }
}

//
//  DBProjectFileBaseHandler.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 13/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

// MARK: use pathId and projectId to search file

class DBProjectFileBaseHandler {
    fileprivate struct Constant {
        static let entityName = "ProjectFile"
    }
    
    static let shared = DBProjectFileBaseHandler()
    private init() {}
    
    fileprivate var context: NSManagedObjectContext {
        get {
            if let context = NXLoginUser.sharedInstance.dataController?.managedObjectContext {
                return context
            } else {
                fatalError()
            }
        }
    }
    
    // TODO: filter only support sort and size now.
    func getFileUnderFolder(with nxProject: NXProject, nxFolder: NXProjectFolder?, filter: NXProjectFileFilter?) -> [NXProjectFileBase] {
        let isRoot = (nxFolder == nil) ? true : false
        let project = DBProjectHandler.shared.fetch(with: nxProject, isActive: true)
        
        guard let files = project?.file as? Set<ProjectFile> else {
            return []
        }
        
        var dbFile: [ProjectFile]
        if isRoot {
            dbFile = files.filter() { $0.parentFile == nil }
        } else {
            let dbFolder = files.filter() { $0.pathId == nxFolder!.fullServicePath }
            guard dbFolder.count == 1, let folder = dbFolder.first else {
                return []
            }
            dbFile = Array(folder.subFile as! Set<ProjectFile>)
        }
        
        if let filter = filter {
            let sortDes = filter.orderBy.map() {
                sort -> NSSortDescriptor in
                var sortDescriptor: NSSortDescriptor
                switch sort {
                case .createTime(let isAscend):
                    sortDescriptor = NSSortDescriptor(key: "creationTime", ascending: isAscend)
                case .fileName(let isAscend):
                    sortDescriptor = NSSortDescriptor(key: "name", ascending: isAscend, selector: #selector(NSString.localizedStandardCompare(_:)))
                }
                
                return sortDescriptor
            }
            dbFile = NSArray(array: dbFile).sortedArray(using: sortDes) as! [ProjectFile]
            if let size = Int(filter.size) {
                dbFile = Array(dbFile.prefix(size))
            }
        }
        
        let nxFile = dbFile.map() { DBProjectFileBaseHandler.convert(from: $0) }
        return nxFile
    }
    
    func getFileDetail(with file: NXProjectFileBase) -> NXProjectFileBase? {
        let project = NXProject()
        project.projectId = file.projectId
        if let dbFile = fetch(with: project, pathId: file.fullServicePath) {
            let file = DBProjectFileBaseHandler.convert(from: dbFile)
            return file
        }
        
        return nil
    }
    
    func syncFileUnderFolder(with nxProject: NXProject, folder: NXProjectFolder?, files: [NXProjectFileBase], isWithDelete: Bool) -> Bool {
        let olds = getFileUnderFolder(with: nxProject, nxFolder: folder, filter: nil)
        let (updates, adds, deletes) = NXCommonUtils.diffChanges(olds: olds, news: files)
        
        for file in updates {
            _ = update(with: nxProject, file: file)
        }
        
        for file in adds {
            _ = addUnderFolder(with: nxProject, folder: folder, file: file)
        }
        
        if isWithDelete {
            for file in deletes {
                _ = delete(with: nxProject, file: file)
            }
        }
        
        save()
        
        return true
    }
    
    func addFileUnderFolder(with nxProject: NXProject, folder: NXProjectFolder?, file: NXProjectFileBase) -> Bool {
        _ = addUnderFolder(with: nxProject, folder: folder, file: file)
        save()
        
        return true
    }
    
    func deleteFile(with file: NXProjectFileBase) -> Bool {
        let project = NXProject()
        project.projectId = file.projectId
        
        _ = delete(with: project, file: file)
        save()
        
        return true
    }
    
    func updateFile(with file: NXProjectFileBase) -> Bool {
        let project = NXProject()
        project.projectId = file.projectId
        
        _ = update(with: project, file: file)
        save()
        
        return true
    }
}

extension DBProjectFileBaseHandler {
    
    fileprivate func fetch(with project: NXProject, pathId: String) -> ProjectFile? {
        let dbProject = DBProjectHandler.shared.fetch(with: project, isActive: true)
        if let fileSet = dbProject?.file as? Set<ProjectFile> {
            let file = fileSet.filter() { $0.pathId == pathId }
            
            guard file.count == 1, let object = file.first else {
                return nil
            }
            
            return object
        }
        
        return nil
    }
    
    fileprivate func update(with project: NXProject, file: NXProjectFileBase) -> Bool {
        if let db = fetch(with: project, pathId: file.fullServicePath) {
            DBProjectFileBaseHandler.format(from: file, to: db)
        }
        
        return true
    }
    
    fileprivate func addUnderFolder(with project: NXProject, folder: NXProjectFolder?, file: NXProjectFileBase) -> Bool {
        let dbParentFile = (folder == nil) ? nil : fetch(with: project, pathId: folder!.fullServicePath)
        
        
        let dbFile = add(with: project, file: file)
        dbFile.parentFile = dbParentFile
        
        return true
    }
    
    fileprivate func add(with project: NXProject, file: NXProjectFileBase) -> ProjectFile {
        let db = ProjectFile(entity: NSEntityDescription.entity(forEntityName: Constant.entityName, in: context)!, insertInto: context)
        DBProjectFileBaseHandler.format(from: file, to: db)
        
        let dbProject = DBProjectHandler.shared.fetch(with: project, isActive: true)
        db.project = dbProject
        
        return db
    }
    
    fileprivate func delete(with project: NXProject, file: NXProjectFileBase) -> Bool {
        if let db = fetch(with: project, pathId: file.fullServicePath) {
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
    
    static func format(from nxFile: NXProjectFileBase, to file: ProjectFile) {
        // format from NXFileBase
        file.name = nxFile.name
        file.size = nxFile.size
        file.pathId = nxFile.fullServicePath
        file.pathDisplay = nxFile.fullPath
        file.lastModified = nxFile.lastModifiedDate as Date
        file.ext_attr = NSKeyedArchiver.archivedData(withRootObject: nxFile.extraInfor)
        file.converted_path = nxFile.convertedPath
        
        // local
        if !nxFile.localPath.isEmpty {
            file.local_path = nxFile.localPath
            file.local_lastModified = nxFile.localLastModifiedDate
        }
        
        // format from NXProjectFileBase
        file.fileId = nxFile.fileId
        
        let project = NXProject()
        project.projectId = nxFile.projectId
        project.name = nxFile.projectName
        file.project = DBProjectHandler.shared.fetch(with: project, isActive: true)
        
        if let creationTime = nxFile.creationTime {
            file.creationTime = NSDate.init(timeIntervalSince1970: creationTime) as Date
        }
        
        if let owner = nxFile.owner {
            file.owner = NSKeyedArchiver.archivedData(withRootObject: owner)
        }
        
        // format from NXProjectFile
        if let nxProjectFile = nxFile as? NXProjectFile {
            file.isFolder = false
            file.isOwner = nxProjectFile.ownerByMe ?? false
            file.duid = (nxProjectFile.duid == nil) ? (nxProjectFile.getNXLID()) : nxProjectFile.duid
            file.isNXL = nxProjectFile.isNXL
            if let rights = nxProjectFile.rights {
                let rights = rights.map() { $0.rawValue }
                file.rights = NSKeyedArchiver.archivedData(withRootObject: rights) as Data
            }
            
        } else {
            file.isFolder = true
        }
        
    }
    
    static func convert(from file: ProjectFile) -> NXProjectFileBase {
        
        let convertToProjectFileBase: (NXProjectFileBase) -> Void = {
            nxFile in
            
            if let name = file.name {
                nxFile.name = name
            }
            nxFile.size = file.size
            if let pathId = file.pathId {
                nxFile.fullServicePath = pathId
            }
            if let pathDisplay = file.pathDisplay {
                nxFile.fullPath = pathDisplay
            }
            if let lastModified = file.lastModified {
                nxFile.lastModifiedDate = lastModified as NSDate
                
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
                let timeString = formatter.string(from: lastModified as Date)
                nxFile.lastModifiedTime = timeString
            }
            nxFile.objectId = file.objectID
            
            if let dic = NSKeyedUnarchiver.unarchiveObject(with: file.ext_attr! as Data) as? [String: Any] {
                nxFile.extraInfor = dic
            }
            
            if let localPath = file.local_path {
                nxFile.localPath = localPath
            }
            
            if let convertedPath = file.converted_path{
                nxFile.convertedPath = convertedPath
            }
            
            nxFile.localLastModifiedDate = file.local_lastModified as Date?
            
            nxFile.fileId = file.fileId
            nxFile.projectId = file.project?.projectId
            nxFile.projectName = file.project?.name
            nxFile.owner = NSKeyedUnarchiver.unarchiveObject(with: file.owner! as Data) as? NXProjectOwner
            nxFile.creationTime = file.creationTime?.timeIntervalSince1970
        }
        
        var nxFile: NXProjectFileBase
        if file.isFolder {
            let projectFolder = NXProjectFolder()
            convertToProjectFileBase(projectFolder)
            
            nxFile = projectFolder
            
        } else {
            let projectFile = NXProjectFile()
            convertToProjectFileBase(projectFile)
        
            projectFile.duid = file.duid
            projectFile.setNXLID(nxlId: file.duid)
            
            projectFile.isNXL = file.isNXL
            
            nxFile = projectFile
            
        }
        
        return nxFile
    }
}

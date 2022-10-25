//
//  DBSharedWithMeFileHandler.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 28/07/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class DBSharedWithMeFileHandler {
    fileprivate struct Constant {
        static let entityName = "SharedWithMeFile"
    }
    
    static let shared = DBSharedWithMeFileHandler()
    
    fileprivate var context: NSManagedObjectContext {
        get {
            if let context = NXLoginUser.sharedInstance.dataController?.managedObjectContext {
                return context
            } else {
                fatalError()
            }
        }
    }
    
    func getAll() -> [NXSharedWithMeFile] {
        let request = NSFetchRequest<SharedWithMeFile>(entityName: Constant.entityName)
        let result = DBCommonUtil.fetchResult(withContext: context, request: request)
        
        let files = result.map() { dbFile -> NXSharedWithMeFile in
            let file = NXSharedWithMeFile()
            DBSharedWithMeFileHandler.formatDB(from: dbFile, to: file)
            return file
        }
        
        return files
    }
    
    func updateAll(with files: [NXSharedWithMeFile]) -> Bool {
        let olds = getAll()
        let (updates, adds, deletes) = NXCommonUtils.diffChanges(olds: olds, news: files)
        
        for file in updates {
            _ = update(with: file)
        }
        for file in adds {
            _ = add(with: file)
        }
        for file in deletes {
            _ = delete(with: file)
        }
        save()
        
        return true
    }
}

extension DBSharedWithMeFileHandler {
    static func format(from: NXSharedWithMeFile, to: SharedWithMeFile) {
        DBFileBaseHandler.formatFileBase(src: from, target: to)
        
        to.duid = from.getNXLID()
        
        to.fileType = from.fileType
        to.sharedDate = from.sharedDate
        to.sharedBy = from.sharedBy
        to.transactionId = from.transactionId
        to.transactionCode = from.transactionCode
        to.sharedLink = from.sharedLink
        to.comment = from.comment
        
        if let rights = from.rights {
            let rights = rights.map() { $0.rawValue }
            to.rights = NSKeyedArchiver.archivedData(withRootObject: rights)  as Data  
        }
    }
    
    static func formatDB(from: SharedWithMeFile, to: NXSharedWithMeFile) {
        DBFileBaseHandler.formatNXFileBase(src: from, target: to)
        
        to.fileType = from.fileType
        to.sharedDate = from.sharedDate
        to.sharedBy = from.sharedBy
        to.transactionId = from.transactionId
        to.transactionCode = from.transactionCode
        to.sharedLink = from.sharedLink
        to.comment = from.comment
    }
}

extension DBSharedWithMeFileHandler {
    
    fileprivate func fetch(with file: NXSharedWithMeFile) -> SharedWithMeFile? {
        let request = NSFetchRequest<SharedWithMeFile>(entityName: Constant.entityName)
        if let duid = file.getNXLID() {
            request.predicate = NSPredicate(format: "duid == %@", duid)
        }
        
        let result = DBCommonUtil.fetchResult(withContext: context, request: request)
        guard result.count == 1, let object = result.first else {
            return nil
        }
        
        return object
    }
    
    fileprivate func update(with file: NXSharedWithMeFile) -> Bool {
        if let dbFile = fetch(with: file) {
            DBSharedWithMeFileHandler.format(from: file, to: dbFile)
        }
        
        return true
    }
    
    fileprivate func add(with file: NXSharedWithMeFile) -> Bool {
        let dbFile = SharedWithMeFile(entity: NSEntityDescription.entity(forEntityName: Constant.entityName, in: context)!, insertInto: context)
        DBSharedWithMeFileHandler.format(from: file, to: dbFile)
        
        return true
    }
    
    fileprivate func delete(with file: NXSharedWithMeFile) -> Bool {
        if let file = fetch(with: file) {
            context.delete(file)
            
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

}

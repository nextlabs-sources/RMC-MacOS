//
//  DBWillUploadFileHandler.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 09/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class DBWillUploadFileHandler {
    struct Constant {
        static let entityName = "WillUploadFile"
    }
    
    // Singleton.
    static let shared = DBWillUploadFileHandler()
    private init() {}
    
    var context: NSManagedObjectContext! {
        get {
            return NXLoginUser.sharedInstance.dataController?.managedObjectContext
        }
    }
}


extension DBWillUploadFileHandler {
    // MARK: API
    func getAll() -> [NXWillUploadFile] {
        let request = NSFetchRequest<WillUploadFile>(entityName: Constant.entityName)
        let result = DBCommonUtil.fetchResult(withContext: context, request: request)
        
        let files = result.map() { dbFile -> NXWillUploadFile in
            let file = NXWillUploadFile()
            DBWillUploadFileHandler.transform(from: dbFile, to: file)
            return file
        }
        
        return files
    }
    
    func modify(with files: [NXWillUploadFile], isDelete: Bool) {
        let olds = getAll()
        let (updates, adds, deletes) = NXCommonUtils.diffChanges(olds: olds, news: files)
        
        for file in updates {
            _ = update(with: file)
        }
        for file in adds {
            _ = add(with: file)
        }
        if isDelete {
            for file in deletes {
                _ = delete(with: file)
            }
        }
        
        _ = save()
    }
}

extension DBWillUploadFileHandler {
    static func transform(from: WillUploadFile, to: NXWillUploadFile) {
        DBFileBaseHandler.formatNXFileBase(src: from, target: to)
        
        to.duid = from.duid
        to.willShare = from.willShare
        to.willProtect = from.willProtect
        to.willSharedWith = from.willSharedWith
        to.comment = from.comment
    }
    
    static func transform(from: NXWillUploadFile, to: WillUploadFile) {
        DBFileBaseHandler.formatFileBase(src: from, target: to)
        
        to.duid = from.duid
        to.willShare = from.willShare
        to.willProtect = from.willProtect
        to.willSharedWith = from.willSharedWith
        to.comment = from.comment
    }
}

extension DBWillUploadFileHandler {
    // MARK: Atomic operation
    fileprivate func fetch(with file: NXWillUploadFile) -> WillUploadFile? {
        guard let duid = file.duid else {
            return nil
        }
        // FetchRequest use 'duid' as primary key.
        let request = NSFetchRequest<WillUploadFile>(entityName: Constant.entityName)
        request.predicate = NSPredicate(format: "duid == %@", duid)
        let result = DBCommonUtil.fetchResult(withContext: context, request: request)
        guard result.count == 1, let object = result.first else {
            return nil
        }
        
        return object
    }
    
    fileprivate func update(with file: NXWillUploadFile) -> Bool {
        if let dbFile = fetch(with: file) {
            DBWillUploadFileHandler.transform(from: file, to: dbFile)
            return true
        }
        
        return false
    }
    
    fileprivate func add(with file: NXWillUploadFile) -> Bool {
        let dbFile = WillUploadFile(entity: NSEntityDescription.entity(forEntityName: Constant.entityName, in: context)!, insertInto: context)
        DBWillUploadFileHandler.transform(from: file, to: dbFile)
        
        return true
    }
    
    fileprivate func delete(with file: NXWillUploadFile) -> Bool {
        if let dbFile = fetch(with: file) {
            context.delete(dbFile)
            return true
        }
        
        return false
    }
    
    fileprivate func save() -> Bool {
        do {
            try context.save()
            return true
        } catch {
            print("Save CoreData-WillUploadFile failed.")
            return false
        }
    }
}

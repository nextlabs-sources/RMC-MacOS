//
//  DBMyVaultFileHandler.swift
//  skyDRM
//
//  Created by pchen on 11/04/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class DBMyVaultFileHandler {
    
    fileprivate struct Constant {
        static let entityName = "MyVaultFile"
    }
    
    static let shared = DBMyVaultFileHandler()

    var context: NSManagedObjectContext? {
        get {
            return NXLoginUser.sharedInstance.dataController?.managedObjectContext
        }
    }
    
    fileprivate let userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!
    
    private init() {
    }
    
    func getAll() -> [NXNXLFile] {
        let request = NSFetchRequest<MyVaultFile>(entityName: Constant.entityName)
        let result = DBCommonUtil.fetchResult(withContext: context!, request: request)
        
        let files = result.map() { dbFile -> NXNXLFile in
            let file = NXNXLFile()
            DBMyVaultFileHandler.format(from: dbFile, to: file)
            return file
        }
        return files
    }
    
    func updateAll(withBoundService bs: NXBoundService, files: [NXNXLFile]) -> Bool {
        let olds = getAll()
        for file in files { file.boundService = bs }
        let (updates, adds, deletes) = NXCommonUtils.diffChanges(olds: olds, news: files)
        
        if update(files: Array(updates)),
            add(files: Array(adds)),
            delete(files: Array(deletes)) {
            save()
            return true
        }
        
        return false
    }
    
    func fetchMyVaultFile(with pathId: String) -> MyVaultFile? {
        guard let userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId) else {
            return nil
        }
        
        let request = NSFetchRequest<MyVaultFile>(entityName: "MyVaultFile")
        request.predicate = NSPredicate(format: "full_cloud_path == %@", pathId)
        
        let result = DBCommonUtil.fetchResult(withContext: context!, request: request)
        
        for fileBase in result {
            if fileBase.boundService?.user_id == userId {
                return fileBase
            }
        }
        
        return nil
    }
    
    func updateAll() -> Bool {
        save()
        return true
    }
}

extension DBMyVaultFileHandler {
    static func format(from: MyVaultFile, to: NXNXLFile) {
        DBFileBaseHandler.formatNXFileBase(src: from, target: to)
        
        to.sharedWith = from.sharedWith
        to.sharedOn = from.sharedOn
        to.isShared = from.isShared
        to.isRevoked = from.isRevoked
        to.isDeleted = from.is_Deleted
        to.customMetadata = NXMyVaultFileCustomMetadata(sourceRepoName: from.sourceRepoName,
                                                        sourceRepoType: from.sourceRepoType,
                                                        sourceFilePathDisplay: from.sourceFilePathDisplay,
                                                        sourceFilePathId: from.sourceFilePathId,
                                                        sourceRepoId: from.sourceRepoId)
    }
    
    static func formatMyVaultFile(from: NXNXLFile, to: MyVaultFile) {
        DBFileBaseHandler.formatFileBase(src: from, target: to)
        
        to.sharedWith = from.sharedWith
        if let isShared = from.isShared {
            to.isShared = isShared
        }
        if let isRevoked = from.isRevoked {
            to.isRevoked = isRevoked
        }
        if let isDeleted = from.isDeleted {
            to.is_Deleted = isDeleted
        }
        to.sourceRepoName = from.customMetadata?.sourceRepoName
        to.sourceRepoType = from.customMetadata?.sourceRepoType
        to.sourceFilePathDisplay = from.customMetadata?.sourceFilePathDisplay
        to.sourceFilePathId = from.customMetadata?.sourceFilePathId
        to.sourceRepoId = from.customMetadata?.sourceRepoId
        
    }
}

extension DBMyVaultFileHandler {
    
    fileprivate func fetchMyVaultFile(from: NXNXLFile) -> MyVaultFile? {
        guard
            let repoId = from.boundService?.repoId
            else { return nil }
        
        let pathId = from.fullServicePath
        let fileBase = DBFileBaseHandler.shared.fetchFileBase(repoId: repoId, pathId: pathId, type: .kServiceMyVault)
        return fileBase as? MyVaultFile
    }
    
    fileprivate func save() {
        do {
            try context?.save()
        } catch {
            fatalError()
        }
    }
    
    fileprivate func update(files: [NXNXLFile]) -> Bool {
        for file in files {
            if let myVault = fetchMyVaultFile(from: file) {
                DBMyVaultFileHandler.formatMyVaultFile(from: file, to: myVault)
            }
            
        }
        
        return true
    }
    
    fileprivate func add(files: [NXNXLFile]) -> Bool {
        for file in files {            
            let myVault = MyVaultFile(entity: NSEntityDescription.entity(forEntityName: "MyVaultFile", in: context!)!, insertInto: context!)
            DBMyVaultFileHandler.formatMyVaultFile(from: file, to: myVault)
        }
        
        return true
    }
    
    fileprivate func delete(files: [NXNXLFile]) -> Bool {
        for file in files {
            if let file = fetchMyVaultFile(from: file) {
                context?.delete(file)
            }
        }
        
        return true
    }
}

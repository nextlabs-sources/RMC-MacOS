//
//  NXDBManager.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 11/06/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

/// Facade pattern.
protocol NXDBManagerOperation {
    func getFileRecords() -> [NXFileRecord]
    func addFileRecord(_ record: NXFileRecord) -> Bool
    func removeFileRecord(_ record: NXFileRecord) -> Bool
    func updateFileRecord(_ record: NXFileRecord) -> Bool
    func removeExpiredFileRecord()
    
}

class NXDBManager {
    static let sharedInstance = NXDBManager()
    
    var coreDataController: NXCoreDataController?
    var fileRecordOperation: NXDBFileRecordHandlerOperation?
    
    func loadCoreDataController(tenant: NXTenant, user: NXUser) {
        coreDataController = NXCoreDataController()
        coreDataController?.shouldAddStoreAsynchronously = false
        coreDataController?.loadPersistentStore(tenant: tenant, user: user) { (error) in
            debugPrint("Load Core Data Error: \(String(describing: error))")
        }
        
        if let controller = coreDataController {
            fileRecordOperation = NXDBFileRecordHandler(coreDataController: controller)
        }
    }
    
    func removeCoreDataController() {
        coreDataController = nil
        fileRecordOperation = nil
    }
}

extension NXDBManager: NXDBManagerOperation {
    func getFileRecords() -> [NXFileRecord] {
        if let items = fileRecordOperation?.getAll() {
            return items
        }
        
        return []
    }
    @discardableResult
    func addFileRecord(_ record: NXFileRecord) -> Bool {
        return fileRecordOperation?.add(record: record) ?? false
    }
    @discardableResult
    func removeFileRecord(_ record: NXFileRecord) -> Bool {
        return fileRecordOperation?.remove(record: record) ?? false
    }
    @discardableResult
    func updateFileRecord(_ record: NXFileRecord) -> Bool {
        return fileRecordOperation?.update(record: record) ?? false
    }
    
    func removeExpiredFileRecord() {
        fileRecordOperation?.removeExpiredFileRecord()
    }
    
    
}

// MARK: Common method.

extension NXDBManager {
    @discardableResult
    static func save(context: NSManagedObjectContext) -> Error? {
        do {
            try context.save()
        } catch {
            return error
        }
        return nil
    }
    
    
    static func backgroundMocSave(context: NSManagedObjectContext,parentContext:NSManagedObjectContext) -> Error? {
        do {
            try context.save()
            parentContext.performAndWait {
                do{
                    try parentContext.save()
                }catch{
                    fatalError("Failure to save parent Context: \(error)")
                }
            }
        } catch {
            return error
        }
        return nil
    }
    
    static func fetch<T>(context: NSManagedObjectContext, request: NSFetchRequest<T>) -> [T]? {
        do {
            let result = try context.fetch(request)
            return result
        } catch {
            return nil
        }
    }
    
    static func fetchOne<T>(context: NSManagedObjectContext, request: NSFetchRequest<T>) -> T? {
        guard let result = fetch(context: context, request: request) else {
            return nil
        }
        
        guard result.count == 1, let object = result.first  else {
            return nil
        }
        
        return object
    }
}

//
//  NXDBUploadOperationHandler.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 11/06/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

protocol NXDBFileRecordHandlerOperation {
    func getAll() -> [NXFileRecord]?
    func add(record: NXFileRecord) -> Bool
    func remove(record: NXFileRecord) -> Bool
    func update(record: NXFileRecord) -> Bool
    func removeExpiredFileRecord()
    
}

// TODO: Only Support nxl.
class NXDBFileRecordHandler {
    init(coreDataController: NXCoreDataController) {
        self.coreDataController = coreDataController
    }
    
    struct Constant {
        static let entityName = "FileRecord"
        static let lastLevel: Int16 = 1
    }
    
    weak var coreDataController: NXCoreDataController?
}

extension NXDBFileRecordHandler: NXDBFileRecordHandlerOperation {
    func getAll() -> [NXFileRecord]? {
        let requset = NSFetchRequest<FileRecord>(entityName: Constant.entityName)
        let modifyTimeSort = NSSortDescriptor(key: #keyPath(FileRecord.modifyTime), ascending: true)
        requset.sortDescriptors = [modifyTimeSort]
        if let dbRecords = NXDBManager.fetch(context: (coreDataController?.viewContext)!, request: requset), !dbRecords.isEmpty {
            let records = dbRecords.map() { dbRecord -> NXFileRecord in
                return self.transform(from: dbRecord)
            }
            return records
        }
        
        return nil
    }
    
    func add(record: NXFileRecord) -> Bool {
        
        let newContext = self.coreDataController!.newPrivateContext()
        let dbItem = NSEntityDescription.insertNewObject(forEntityName: Constant.entityName, into: newContext) as! FileRecord
        self.transform(from: record, to: dbItem)
        dbItem.level = Constant.lastLevel
        if NXDBManager.backgroundMocSave(context:newContext, parentContext: self.coreDataController!.viewContext) == nil {
            return true
        }
        
        return false
    }
    
    func remove(record: NXFileRecord) -> Bool {
        let newContext = self.coreDataController!.newPrivateContext()
        if let dbItem = fetch(record,inContext: newContext) {
            newContext.delete(dbItem)
            if NXDBManager.backgroundMocSave(context:newContext, parentContext: self.coreDataController!.viewContext) == nil {
                return true
            }
        }
        return false
    }
    
    func update(record: NXFileRecord) -> Bool {
        let newContext = self.coreDataController!.newPrivateContext()
        if let dbItem = fetch(record,inContext:newContext) {
            self.transform(from: record, to: dbItem)
            dbItem.level = Constant.lastLevel
            if NXDBManager.backgroundMocSave(context:newContext, parentContext: self.coreDataController!.viewContext) == nil {
                return true
            }
        }else{
            let dbItem = NSEntityDescription.insertNewObject(forEntityName: Constant.entityName, into: newContext) as! FileRecord
            self.transform(from: record, to: dbItem)
            dbItem.level = Constant.lastLevel
            if NXDBManager.backgroundMocSave(context:newContext, parentContext: self.coreDataController!.viewContext) == nil {
                return true
            }
        }
          return false
    }
    
    func removeExpiredFileRecord() {
        let newContext = self.coreDataController!.newPrivateContext()
        let requset = NSFetchRequest<FileRecord>(entityName: Constant.entityName)
        let modifyTimeSort = NSSortDescriptor(key: #keyPath(FileRecord.modifyTime), ascending: true)
        requset.sortDescriptors = [modifyTimeSort]
        if let dbRecords = NXDBManager.fetch(context: newContext, request: requset), !dbRecords.isEmpty {
            
            for dbRecord in dbRecords {
                if dbRecord.level <= 0 {
                    newContext.delete(dbRecord)
                } else {
                    dbRecord.level -= 1
                }
            }
            if NXDBManager.backgroundMocSave(context:newContext, parentContext: self.coreDataController!.viewContext) == nil{
                YMLog("remove expired file record successful")
            }
        }
    }
}

extension NXDBFileRecordHandler {
    fileprivate func fetch(_ item: NXFileRecord) -> FileRecord? {
        let request = NSFetchRequest<FileRecord>(entityName: Constant.entityName)
        request.predicate = NSPredicate(format: "fileID == %@",item.fileID)
        // Get result from request.
        let result = NXDBManager.fetchOne(context: (coreDataController?.viewContext)!, request: request)
        return result
    }
    
    fileprivate func fetch(_ item: NXFileRecord,inContext:NSManagedObjectContext) -> FileRecord? {
        let request = NSFetchRequest<FileRecord>(entityName: Constant.entityName)
        request.predicate = NSPredicate(format: "fileID == %@", item.fileID)
        // Get result from request.
        let result = NXDBManager.fetchOne(context: inContext, request: request)
        return result
    }
    
}

// MARK: - Transform.

extension NXDBFileRecordHandler {
    func transform(from: FileRecord) -> NXFileRecord {
        let type = NXRecordType(rawValue: Int(from.type))!
        let filename = from.filename!
        let fileID = from.fileID!
        var fileStatus : NXSyncState?
        if from.fileStatus != -1 {
            fileStatus = NXSyncState(rawValue: Int(from.fileStatus))
        }
        
        let record = NXFileRecord(type: type, filename: filename, fileID: fileID, fileStatus: fileStatus)
        
        return record
    }
    
    func transform(from: NXFileRecord, to: FileRecord) {
        to.type = Int16(from.type.rawValue)
        to.filename = from.filename
        to.fileID = from.fileID
        if let status = from.fileStatus {
            to.fileStatus = Int16(status.rawValue)
        } else {
            to.fileStatus = -1
        }
        
        to.modifyTime = Date() 

    }
}

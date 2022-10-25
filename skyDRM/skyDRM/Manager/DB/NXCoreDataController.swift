
//
//  NXCoreDataController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 11/06/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

// MARK: - Core Data stack

class NXCoreDataController {
    
    struct Constant {
        static let modelName = "NXLocalDataModel"
        static let databaseName = "NXLocalDataModel"
        static let databaseExtension = "storedata"
        static let dbFolderName = "db"
    }
    
    private var persistentContainer: NSPersistentContainer
    
    /// A read-only flag indicating if the persistent store is loaded.
    private(set) var isStoreLoaded = false
    
    var shouldAddStoreAsynchronously = false
    
    var viewContext: NSManagedObjectContext {
        return persistentContainer.viewContext
    }
    
    var backgroundContext: NSManagedObjectContext?
    
    init?() {
        let bundle = Bundle(for: NXCoreDataController.self)
        guard let mom = NSManagedObjectModel.mergedModel(from: [bundle]) else {
            return nil
        }
        
        persistentContainer = NSPersistentContainer(name: Constant.modelName, managedObjectModel: mom)
        backgroundContext = NSManagedObjectContext.init(concurrencyType: NSManagedObjectContextConcurrencyType.privateQueueConcurrencyType)
        backgroundContext!.parent = self.viewContext
    }
    
    func loadPersistentStore(tenant: NXTenant, user: NXUser, completion: @escaping (Error?) -> ()) {
        // Check store url.
        let dbFolderURL = getDBFolderURL(tenant: tenant, user: user)
        if let error = checkDBFolder(url: dbFolderURL) {
            completion(error)
            return
        }
        
        let storeURL = getPersistentStoreURL(tenant: tenant, user: user)
        let storeDescription = getStoreDescription(url: storeURL)
        persistentContainer.persistentStoreDescriptions = [storeDescription]
        persistentContainer.loadPersistentStores() { (description, error) in
            if error == nil {
                self.isStoreLoaded = true
            }
            
            completion(error)
            return
        }
    }
    
    private func checkDBFolder(url: URL) -> Error? {
        if FileManager.default.fileExists(atPath: url.path) {
            return nil
        }
        
        do {
            try FileManager.default.createDirectory(at: url, withIntermediateDirectories: true, attributes: nil)
        } catch {
            return error
        }
        
        return nil
    }
    
    /// path: ~/Library/Application Support/'BundleID'/'tenantID'/'userID'/db/NXLocalDataModel.storedata
    ////~/Library/Containers/com.nxrmc.skyDRM/Data/Library/Application Support/com.nxrmc.skyDRM/rmtest.nextlabs.solutions/skydrm.com/306/db
    
    private func getDBFolderURL(tenant: NXTenant, user: NXUser) -> URL {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls.last!
        let bundleID = Bundle.main.bundleIdentifier!
        let router = tenant.routerURL
        let routerId = (URL(string: router)?.host) ?? ""
        
        let dbFolderURL = appSupportURL.appendingPathComponent(bundleID, isDirectory: true).appendingPathComponent(routerId, isDirectory: true).appendingPathComponent(tenant.tenantID, isDirectory: true).appendingPathComponent(user.userID, isDirectory: true).appendingPathComponent(Constant.dbFolderName, isDirectory: true)
        
        return dbFolderURL
    }
    
    private func getPersistentStoreURL(tenant: NXTenant, user: NXUser) -> URL {
        let dbFolderURL = getDBFolderURL(tenant: tenant, user: user)
        let storeName = Constant.databaseName + "." + Constant.databaseExtension
        let storeURL = dbFolderURL.appendingPathComponent(storeName, isDirectory: false)
        
        return storeURL
    }
    
    private func getStoreDescription(url: URL) -> NSPersistentStoreDescription {
        let storeDescription = NSPersistentStoreDescription(url: url)
        storeDescription.type = NSXMLStoreType
        storeDescription.shouldAddStoreAsynchronously = shouldAddStoreAsynchronously
        return storeDescription
    }
    
    /// Execute a block on a new private queue context.
    ///
    /// - Parameter block: A block to execute on a newly created private
    ///   context. The context is passed to the block as a parameter.
    
    func performBackgroundTask(block: @escaping (NSManagedObjectContext) -> Void) {
        persistentContainer.performBackgroundTask(block)
    }
    
    
    /// Create and return a new private queue `NSManagedObjectContext`. The
    /// new context is set to consume `NSManagedObjectContextSave` broadcasts
    /// automatically.
    ///
    /// - Returns: A new private managed object context
    
    func newPrivateContext() -> NSManagedObjectContext {
        objc_sync_enter(self)
        defer {
            objc_sync_exit(self)
        }
        return self.backgroundContext!
    }
}

//
//  CoreDataController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 12/05/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

// MARK: - Core Data stack

class CoreDataController: NSObject {

    var managedObjectContext: NSManagedObjectContext?

    struct Constant {
        static let bundleIdentifier = "com.nxrmc.skyDRM"
        static let modelName = "RMCModel"
    }
    
    private let userRootDirectory: URL = {
        let urls = FileManager.default.urls(for: .applicationSupportDirectory, in: .userDomainMask)
        let appSupportURL = urls.last!
        return appSupportURL.appendingPathComponent(Constant.bundleIdentifier)
    }()
    
    private let managedObjectModel: NSManagedObjectModel = {
        let modelURL = Bundle.main.url(forResource: Constant.modelName, withExtension: "momd")!
        return NSManagedObjectModel(contentsOf: modelURL)!
    }()
    
    init(with userId: String) {
        super.init()
        
        let coordinator = createPersistentStoreCoordinator(with: userId)
        managedObjectContext = createManagedObjectContext(with: coordinator)
    }

    deinit {
        managedObjectContext = nil
        
    }
    
    private func createPersistentStoreCoordinator(with userId: String) -> NSPersistentStoreCoordinator {
        
        let currentUserDirectory = userRootDirectory.appendingPathComponent(userId, isDirectory: true)
        if !FileManager.default.fileExists(atPath: currentUserDirectory.path) {
            do {
                try FileManager.default.createDirectory(at: currentUserDirectory, withIntermediateDirectories: true, attributes: nil)
            } catch {
                fatalError()
            }
            
        }
        
        let psc = NSPersistentStoreCoordinator(managedObjectModel: managedObjectModel)
        let options = [NSMigratePersistentStoresAutomaticallyOption: true, NSInferMappingModelAutomaticallyOption: true]
        
        let storeURL = currentUserDirectory.appendingPathComponent(Constant.modelName + ".storedata")
        do {
            try psc.addPersistentStore(ofType: NSXMLStoreType, configurationName: nil, at: storeURL, options: options)
            return psc
        } catch {
            fatalError("Error migrating store: \(error)")
        }
    }
    
    private func createManagedObjectContext(with coordinator: NSPersistentStoreCoordinator) -> NSManagedObjectContext {
        let managedObjectContext = NSManagedObjectContext(concurrencyType: .mainQueueConcurrencyType)
        managedObjectContext.persistentStoreCoordinator = coordinator
        return managedObjectContext
    }
    
}

extension CoreDataController {
    // MARK: - Core Data Saving and Undo support
    @IBAction func saveAction(_ sender: AnyObject?) {
        // Performs the save action for the application, which is to send the save: message to the application's managed object context. Any encountered errors are presented to the user.
        guard let managedObjectContext = managedObjectContext else {
            return
        }
        
        if !managedObjectContext.commitEditing() {
            NSLog("\(NSStringFromClass(type(of: self))) unable to commit editing before saving")
        }
        if managedObjectContext.hasChanges {
            do {
                try managedObjectContext.save()
            } catch {
                let nserror = error as NSError
                NSApplication.shared.presentError(nserror)
            }
        }
    }
}

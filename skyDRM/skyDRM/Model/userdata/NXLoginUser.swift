//
//  NXLoginUser.swift
//  skyDRM
//
//  Created by nextlabs on 12/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation
import Alamofire

class NXMyDriveStorage: NSObject {
    
    override init() {
        super.init()
    }
    
    init(used: Int64, total: Int64, myvault: Int64) {
        self.used = used
        self.total = total
        self.myvault = myvault
        
        super.init()
    }
    
    var used: Int64 = 0
    var total: Int64 = 0
    var myvault: Int64 = 0
    func reset() {
        used = 0
        total = 0
        myvault = 0
    }
}

class NXProjectStorage: NSObject {
    @objc dynamic var ownerProjectList: [NXProject] = [NXProject]()
    @objc dynamic var joinedProjectList: [NXProject] = [NXProject]()
    @objc dynamic var pendingInvitationsList: [NXProjectInvitation] = [NXProjectInvitation]()
    func reset() {
        ownerProjectList.removeAll()
        joinedProjectList.removeAll()
        pendingInvitationsList.removeAll()
    }

}

class NXLoginUser: NSObject {
    
    @objc dynamic var nxlClient: NXLClient? {
        didSet {
            if let currentUser = nxlClient {
                dataController = CoreDataController(with: currentUser.userID)
                // Listen for user network status
                createReachablility()
            } else {
                dataController = nil
            }
            
        }
    }
    
    static let sharedInstance = NXLoginUser()
    @objc dynamic var myDriveStorage = NXMyDriveStorage()
    var projectStorage = NXProjectStorage()
    private let projectLock = NSLock()
    @objc private dynamic var repositoryArray = [NXRMCRepoItem]()
    private let repositoryLock = NSLock()
    
    var dataController: CoreDataController?
    
    var networkManager: NetworkReachabilityManager?
    @objc dynamic var networkStatus = true
    
    private override init(){
    }
    public func clear() {
        nxlClient = nil
        myDriveStorage.reset()
        projectStorage.reset()
        repositoryArray.removeAll()
        
    }
    public func addRepository(repository: NXRMCRepoItem) {
        repositoryLock.lock()
        if repositoryArray.contains(repository) == false {
            repositoryArray.append(repository)
        }
        repositoryLock.unlock()
    }
    public func removeRepository(repository: NXRMCRepoItem) {
        repositoryLock.lock()
        if let index = repositoryArray.firstIndex(of: repository) {
            repositoryArray.remove(at: index)
        }
        repositoryLock.unlock()
    }
    public func updateRepository(repository: NXRMCRepoItem) {
        repositoryLock.lock()
        if let index = repositoryArray.firstIndex(of: repository) {
            repositoryArray[index] = repository
        }
        repositoryLock.unlock()
    }
    public func repository(repositories: [NXRMCRepoItem]) {
        repositoryLock.lock()
        repositoryArray = repositories
        repositoryLock.unlock()
    }
    public func repository() -> [NXRMCRepoItem] {
        return repositoryArray
    }
    
    public func projects() -> NXProjectStorage {
        return projectStorage
    }
    
    public func updateprojectStorage(projectStorage: NXProjectStorage) {
        projectLock.lock()
        self.projectStorage.joinedProjectList = projectStorage.joinedProjectList
        self.projectStorage.ownerProjectList = projectStorage.ownerProjectList
        self.projectStorage.pendingInvitationsList = projectStorage.pendingInvitationsList
        projectLock.unlock()
    }
    public func updateProject(project: NXProject) {
        defer {
            projectLock.unlock()
        }
        projectLock.lock()
        for (index, item) in projectStorage.joinedProjectList.enumerated() {
            if item.projectId == project.projectId {
                projectStorage.joinedProjectList[index] = project
                return
            }
        }
        for (index, item) in projectStorage.ownerProjectList.enumerated() {
            if item.projectId == project.projectId {
                projectStorage.ownerProjectList[index] = project
                return
            }
        }
    }
    
    func createReachablility() {
        let manager = NetworkReachabilityManager()
        self.networkManager = manager
        manager?.listener = { status in
            if case NetworkReachabilityManager.NetworkReachabilityStatus.reachable = status  {
                self.networkStatus = true
            } else {
                self.networkStatus = false
            }
            
            print("Network Status Changed: \(status)")
        }
        manager?.startListening()
    }
}


extension NXLoginUser: NXServiceOperationDelegate {
    func updateMySpaceStorage() {
        guard let nxClient = self.nxlClient else {
            return
        }
        let service = NXSkyDrmBox(withUserID: nxClient.profile.userId, ticket: nxClient.profile.ticket)
        
        service.setDelegate(delegate: self)
        if service.getUserInfo() == false {
            Swift.print("fail to get my drive user info")
        }
    }
    func getUserInfoFinishedExtraData(username: String?, email: String?, totalQuota: NSNumber?, usedQuota: NSNumber?, property: Any?, error: NSError?) {
        if error == nil,
            let usedQuota = usedQuota,
            let totalQuota = totalQuota,
            let property = property as! NSNumber? {
            let used = usedQuota.int64Value
            let total = totalQuota.int64Value
            let myvault = property.int64Value
            let storage = NXMyDriveStorage()
            storage.myvault = myvault
            storage.used = used
            storage.total = total
            self.myDriveStorage = storage
        }
        else {
            Swift.print("fail to get my space storage")
        }
    }
}

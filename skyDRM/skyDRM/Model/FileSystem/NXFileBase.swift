//
//  NXFileBase.swift
//  skyDRM
//
//  Created by nextlabs on 30/12/2016.
//  Copyright © 2016 nextlabs. All rights reserved.
//

import Foundation
import SDML

enum NXFileStatus {
    case opened
    case uploading
    case downloading
}

class NXFileBase : NSObject {
    struct Constant {
        static let kNXLId = "nxlId"
        static let kGoogleWebcontentLink = "gdWebconentLink"
        static let kGoogleMimeType = "gdMimeType"
        static let kGoogleExportExtension = "gdExportExtension"
        // Store upload status: unupload, uploading, uploaded, upload failed.
        static let kUploadStatus = "uploadStatus"
        static let defaultUploadStatus = 0
    }
    
    var repoId = String()
    var name = String()
    var fullPath = String()
    var fullServicePath = String()
    
    var lastModifiedTime = String()
    var size = Int64()
    var refreshDate = Date()
    var lastModifiedDate = NSDate()
    
    weak var parent : NXFileBase?
    var isFolder = false
    var children: [NXFileBase]?
    
    var isRoot = Bool()
    
    var serviceAlias = String()
    var serviceAccountId = String()
    var serviceType = NSNumber()
    var isFavorite = Bool()
    var isOffline = Bool()
    var localFile = Bool()
    
    var objectId: NSManagedObjectID? = nil
    var boundService: NXBoundService? = nil
    
    var extraInfor = [String: Any]()
    
    var localLastModifiedDate: Date?
    var localPath = ""
    
    var convertedPath = ""
    
    var sdmlBaseFile: SDMLBaseFile?
    
    var fileStatus = Set<NXFileStatus>()
    var status: NXSyncFileStatus?
    
    func addChild(child : NXFileBase) {
    }
    
    func removeChild(child : NXFileBase) {
    }
    
    func removeAllChildren(){
        
    }
    
    func getChildren() -> NSArray? {
        return nil
    }

    func getNXLID() -> String? {
        return (extraInfor[Constant.kNXLId] as? String)
    }
    
    func setNXLID(nxlId: String?) {
        if let duid = nxlId {
            extraInfor[Constant.kNXLId] = duid
        }
    }
    
    override init(){
        super.init()
    }
    
    /// use to equal 
    override var hash : Int {
        return 0
    }
    
    override func isEqual(_ object: Any?) -> Bool {
        if let object = object as? NXFileBase,
            fullServicePath == object.fullServicePath,
            boundService?.repoId == object.boundService?.repoId,
            boundService?.userId == object.boundService?.userId {
            return true
        }

        return false
    }
    
}

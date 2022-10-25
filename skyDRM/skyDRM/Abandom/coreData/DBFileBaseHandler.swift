/**
 *
 *  used to handle file base persistent data.
 *
 **/

import Foundation
import CoreData

class DBFileBaseHandler{
    var context: NSManagedObjectContext? {
        get {
            return NXLoginUser.sharedInstance.dataController?.managedObjectContext
        }
    }
    
    static let shared = DBFileBaseHandler()
    
    private init(){
    }
    
    //get root file's set through specific bound service
    func getRootWithBoundService(boundService:NXBoundService)->[NXFileBase]{
        if (boundService.objectID == nil)
        {
            return []
        }
        
        let bs = context?.object(with: boundService.objectID!) as! BoundService
        let fileBaseSet = bs.file?.filter{($0 as! FileBase).parentFile == nil} as! [FileBase]
        var nxFileBaseSet:[NXFileBase]? = []
        for file in fileBaseSet{
            var nxFile: NXFileBase? = nil
            if (file.is_file)
            {
                nxFile = NXFile()
            }
            else
            {
                nxFile = NXFolder()
            }
            
            DBFileBaseHandler.formatNXFileBase(src: file, target: nxFile!)
            nxFileBaseSet?.append(nxFile!)
        }
        return nxFileBaseSet!
    }
    
    //add file set to specific bound service.
    func addFiles2BoundService(boundService:NXBoundService, fileBaseSet:NSSet)->Bool{
        if boundService.objectID == nil{
            return false
        }
        
        let bs = context?.object(with: boundService.objectID!) as! BoundService
        
        Swift.print("NXBoundService object ID \(String(describing: boundService.objectID)), related BoundService \(String(describing: bs.service_account))")
        
        for fileBase in fileBaseSet{            
            let file = FileBase(entity: NSEntityDescription.entity(forEntityName: "FileBase", in: context!)!, insertInto: context!)
            file.boundService = bs
            let nxFile = fileBase as! NXFileBase
            
            // save object id into fileBaseSet.
            nxFile.objectId = file.objectID
            nxFile.boundService = boundService
            
            DBFileBaseHandler.formatFileBase(src: nxFile, target: file)
            
        }
        do{
            try context?.save()
            return true
        }catch{
            Swift.print("add files to bound service failed")
            
            // it's better to set objectId of fileBaseSet to nil, but ignore for now.
        }
        
        return false
    }
    
    //add files to target file node.
    func addFiles2TargetNode(fileBaseSet:NSSet, targetNode:NXFileBase)->Bool{
        if (targetNode.objectId == nil){
            return false
        }
        
        let targetFile = context?.object(with: targetNode.objectId!) as! FileBase
        
        Swift.print("targetFile in Core Data: \(targetFile)")
        
        for fileBase in fileBaseSet{

            let file = FileBase(entity: NSEntityDescription.entity(forEntityName: "FileBase", in: context!)!, insertInto: context!)
            let nxFile = fileBase as! NXFileBase
            
            nxFile.objectId = file.objectID
            nxFile.boundService = targetNode.boundService
            
            DBFileBaseHandler.formatFileBase(src: nxFile, target: file)
            
            // set up relationship
            file.parentFile = targetFile
            
            
        }
        do{
         
            try context?.save()
            return true
        }catch let error{
            Swift.print("add files to target node failed, error: \(error)")
            
            // it's better to set objectId of fileBaseSet to nil, but ignore for now.
        }
        return false
    }
    
    //get target nxFileBase's parent node.
    func getParentFileNode(fileBase:NXFileBase)->NXFileBase{
        let parentFileNode:FileBase = context?.object(with: fileBase.objectId!) as! FileBase
        let parentNXFileNode = NXFileBase()
        DBFileBaseHandler.formatNXFileBase(src: parentFileNode.parentFile!, target: parentNXFileNode)
        return parentNXFileNode
    }
    
    //get sub nodes through specific file base node.
    func getSubFiles(fileBase:NXFileBase)->[NXFileBase]{
        let file:FileBase = context?.object(with: fileBase.objectId!) as! FileBase
        var nxFileBaseSet:[NXFileBase] = []
        let fileBaseSet:[FileBase] = file.subFile?.allObjects as! [FileBase]
        for node in fileBaseSet{
            var nxFileBase: NXFileBase? = nil
            if node.is_file{
                nxFileBase = NXFile()
            }else{
                nxFileBase = NXFolder()
            }
            
            DBFileBaseHandler.formatNXFileBase(src: node, target: nxFileBase!)
            nxFileBaseSet.append(nxFileBase!)
        }
        return nxFileBaseSet
    }
    
    
    //delete target file node.
    func deleteTargetFileNode(fileBase:NXFileBase)->Bool{
        let file = context?.object(with: fileBase.objectId!)
        if (context?.delete(file!) != nil){
            do{
                try context?.save()
                return true
            }catch{
                Swift.print("delete file node failed")
            }
        }
       
        return false
    }
    
    //used to update target file node include modify file, cache file path and etc, just pass the NXFile object
    func updateFileNode(fileBase:NXFileBase)->Bool{
        if fileBase.objectId == nil {
            return false 
        }
        let file = context?.object(with: fileBase.objectId!)
        DBFileBaseHandler.formatFileBase(src: fileBase, target: file as! FileBase)
        do{
            try context?.save()
            return true
        }catch{
            Swift.print("udpate file node failed")
        }
        return false
    }
    
    func updateFileNode(fileBases:[NXFileBase])->Bool{
        for fileBase in fileBases {
            if fileBase.objectId != nil {
               let file = context?.object(with: fileBase.objectId!)
               DBFileBaseHandler.formatFileBase(src: fileBase, target: file as! FileBase)
            }
        }

        do{
            try context?.save()
            return true
        }catch{
            Swift.print("udpate file node failed")
        }
        return false
    }
    
    func updateAllFavorite(service: NXBoundService, files: [NXFavFileItem]) -> Bool {
        guard
            let objectId = service.objectID,
            let bs = context?.object(with: objectId) as? BoundService,
            let fileSet = bs.file,
            let filebases = Array(fileSet) as? [FileBase]
            else { return false }
        
        if files.isEmpty {
            // remove all favorite
            _ = filebases.map() { $0.is_favorite = false }
        } else {
            for filebase in filebases {
                if files.contains(where: { $0.pathId == filebase.full_cloud_path }) {
                    filebase.is_favorite = true
                } else {
                    filebase.is_favorite = false
                }
            }
        }
        
        do{
            try context?.save()
            return true
        }catch{
            Swift.print("udpate file node failed")
        }
        
        return false
    }
    
    func updateFavOrOfflineInFileNode(isFav: Bool, fileBases:[NXFileBase])->Bool{
        for fileBase in fileBases {
            if fileBase.objectId != nil {
                let file = context?.object(with: fileBase.objectId!)
                if isFav {
                    (file as! FileBase).is_favorite = fileBase.isFavorite
                } else {
                    (file as! FileBase).is_offline = fileBase.isOffline
                }
            }
        }
        
        do{
            try context?.save()
            return true
        }catch{
            Swift.print("udpate file node failed")
        }
        return false
    }
    
    func getFavoriteFile(in service: NXBoundService) -> [NXFileBase]? {
        guard
            let objectId = service.objectID,
            let bs = context?.object(with: objectId) as? BoundService,
            let fileSet = bs.file,
            let filebases = Array(fileSet) as? [FileBase]
            else { return nil }
        
        let favFileBases = filebases.filter() { $0.is_favorite == true }
        
        var result: [NXFileBase]
        if let favMyVaultFile = favFileBases as? [MyVaultFile]  {
            result = favMyVaultFile.map() { dbFile -> NXNXLFile in
                let file = NXNXLFile()
                DBMyVaultFileHandler.format(from: dbFile, to: file)
                return file
                
            }
        } else {
            result = favFileBases.map() {
                file in
                let nxFile = (file.is_file) ? NXFile(): NXFolder()
                DBFileBaseHandler.formatNXFileBase(src: file, target: nxFile)
                return nxFile
            }
        }
        
        return result
    }
    
    func getAllFavOrOffline(isFav: Bool, bsArray: [NXBoundService]) -> [NXFileBase]
    {
        var result:[NXFileBase] = []
        
        for item in bsArray {
            if (item.objectID != nil)
            {
                let bs = context?.object(with: item.objectID!) as! BoundService
                
                var fileBaseSet:[FileBase] = []
                if isFav {
                    fileBaseSet = bs.file?.filter{($0 as! FileBase).is_favorite == true} as! [FileBase]
                } else {
                    fileBaseSet = bs.file?.filter{($0 as! FileBase).is_offline == true} as! [FileBase]
                }
                
                for file in fileBaseSet{
                    var nxFile: NXFileBase? = nil
                    if (file.is_file)
                    {
                        nxFile = NXFile()
                    }
                    else
                    {
                        nxFile = NXFolder()
                    }
                    
                    DBFileBaseHandler.formatNXFileBase(src: file, target: nxFile!)
                    result.append(nxFile!)
                }
            }
        }
        
        return result
    }
    
    // MARK: Format
    
    public static func formatFileBase(src:NXFileBase, target:FileBase){
        target.file_name = src.name
        target.file_size = src.size
        target.full_cloud_path = src.fullServicePath
        target.full_path = src.fullPath
        target.is_favorite = src.isFavorite
        target.is_offline = src.isOffline
        target.is_file = true
        if (src as? NXFolder) != nil{
            target.is_file = false
        }
        target.last_modified_date = src.lastModifiedDate as Date
        
        if !src.extraInfor.isEmpty {
            let data = try? JSONSerialization.data(withJSONObject: src.extraInfor, options: .prettyPrinted)
            target.ext_attr = data?.base64EncodedString()
        }
    
        if let localLastModifiedDate = src.localLastModifiedDate as NSDate? {
            target.local_lastModifiedDate = localLastModifiedDate as Date
        }
        
        if !src.localPath.isEmpty {
            target.file_local_path = src.localPath
        }
        
        if !src.convertedPath.isEmpty{
            target.converted_path = src.convertedPath
        }
        
        if let boundService = src.boundService {
            target.boundService = DBBoundServiceHandler.shared.fetchBoundService(with: boundService.repoId, type: ServiceType(rawValue: boundService.serviceType))
        }
    }
    
    public static func formatNXFileBase(src:FileBase, target:NXFileBase){
        target.name = src.file_name!
        target.size = src.file_size
        target.fullServicePath = src.full_cloud_path!
        target.fullPath = src.full_path!
        target.isFavorite = src.is_favorite
        target.isOffline = src.is_offline
        target.lastModifiedDate = src.last_modified_date! as NSDate
        target.objectId = src.objectID
        
        
        if let dbBoundService = src.boundService {
            let bs = NXBoundService()
            DBBoundServiceHandler.formatNXBoundService(src: dbBoundService, target: bs)
            target.boundService = bs
            target.serviceType = NSNumber(value: bs.serviceType)
        }
        
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
        let timeString = formatter.string(from: target.lastModifiedDate as Date)
        
        target.lastModifiedTime = timeString
        
        if let extraString = src.ext_attr, let data = Data.init(base64Encoded: extraString) {
            let extraInfor = try? JSONSerialization.jsonObject(with: data, options: .allowFragments)
            
            if let notnilExtraInfor = extraInfor as? [String: Any] {
                target.extraInfor = notnilExtraInfor
            }
            
        }
        
        if let localPath = src.file_local_path {
            target.localPath = localPath
        }
        
        if let convertedPath = src.converted_path{
            target.convertedPath = convertedPath
        }

        target.localLastModifiedDate = src.local_lastModifiedDate as Date?
        
    }
    
    // MARK: Fav, Off
    
    func fetchFileBase(repoId: String, pathId: String, type: ServiceType?) -> FileBase? {
        
        // TODO: FileBase repoId not use yet, so get file from bound service
        
        guard let service = DBBoundServiceHandler.shared.fetchBoundService(with: repoId, type: type) else {
            return nil
        }
        
        guard let files = service.file as? Set<FileBase> else {
            return nil
        }
        
        let result = files.filter{ $0.full_cloud_path == pathId }
        
        guard result.count == 1, let object = result.first else {
            return nil
        }
        
        return object
    }

    func fetchFileBase(with repoId: String, fullPath: String, type: ServiceType?) -> FileBase? {
        
        guard let service = DBBoundServiceHandler.shared.fetchBoundService(with: repoId, type: type) else {
            return nil
        }
        
        guard let files = service.file as? Set<FileBase> else {
            return nil
        }
        
        let result = files.filter{ $0.full_path == fullPath }
        
        guard result.count == 1, let object = result.first else {
            return nil
        }
        
        return object
    }
    
    func fetchFileBase(with pathId: String) -> FileBase? {
        guard let userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId) else {
            return nil
        }
        
        let request = NSFetchRequest<FileBase>(entityName: "FileBase")
        request.predicate = NSPredicate(format: "full_cloud_path == %@", pathId)
        
        let result = DBCommonUtil.fetchResult(withContext: context!, request: request)
        
        for fileBase in result {
            if fileBase.boundService?.user_id == userId {
                return fileBase
            }
        }
        
        return nil
    }
    
    func deleteFileBase(with pathId: String) -> Bool {
        guard let fileBase = fetchFileBase(with: pathId) else {
            return false
        }
        context?.delete(fileBase)
        try? context?.save()
        
        return true
    }
}

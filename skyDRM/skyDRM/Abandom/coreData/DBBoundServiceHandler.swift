/**
 *
 *  used to handle boundservice persistent data.
 *
 **/

import Foundation
import CoreData

class DBBoundServiceHandler{
    var context: NSManagedObjectContext? {
        get {
            return NXLoginUser.sharedInstance.dataController?.managedObjectContext
        }
    }
    
    static let shared = DBBoundServiceHandler()
    
    private init(){

    }
    //get all boundService
    func getAllBoundService() -> [NXBoundService] {
        do{
            let request = NSFetchRequest<BoundService>(entityName: "BoundService")
            
            let result = try context!.fetch(request)
            var nxResult:[NXBoundService] = [NXBoundService]()
            for value in result{
                let temp = NXBoundService()
                DBBoundServiceHandler.formatNXBoundService(src: value, target: temp)
                nxResult.append(temp)
            }
            return nxResult
        }catch{
            Swift.print("get all boundservice failed")
        }
        return [NXBoundService]()
    }
    //get all boundService through user_id
    func getAllBoundServiceWithUserId(userId:String)->[NXBoundService]{
        do{
            let request = NSFetchRequest<BoundService>(entityName: "BoundService")
            
            request.predicate = NSPredicate(format: "user_id == %@", userId)
            let result = try context!.fetch(request)
            var nxResult:[NXBoundService] = [NXBoundService]()
            for value in result{
                let temp = NXBoundService()
                DBBoundServiceHandler.formatNXBoundService(src: value, target: temp)
                nxResult.append(temp)
            }
            return nxResult
        }catch{
            Swift.print("get all boundservice failed")
        }
        return [NXBoundService]()
    }
    
    func getBoundServiceByAccount(userId: String, account: String, type: ServiceType) ->NXBoundService?
    {
        let request = NSFetchRequest<BoundService>(entityName: "BoundService")
        
        request.predicate = NSPredicate(format: "user_id==%@ AND service_account==%@ AND service_type==%d", userId, account, type.rawValue)
        
        do{
            let result = try context!.fetch(request)
            if (result.count != 1)
            {
                Swift.print("can't find boudservice, result: \(result.count)")
                return nil
            }else{
                let temp = NXBoundService()
                DBBoundServiceHandler.formatNXBoundService(src: result[0], target: temp)
                return temp
            }
        }catch{
            Swift.print("getBoundServiceByAccount exception")
        }
        
        return nil
    }
    
    //add a new bound service to core data.
    func addNewBoundService(item:NXBoundService)->Bool{
        do{
            let boundService = BoundService(entity: NSEntityDescription.entity(forEntityName: "BoundService", in: context!)!, insertInto:context!)
            DBBoundServiceHandler.formatBoundService(src:item, target:boundService)
            try context?.save()
            
            item.objectID = boundService.objectID
            
            return true
        }catch{
            Swift.print("save new bound failed")
        }
        return false
    }
    
    //update specific bound service.
    func updateBoundService(item:NXBoundService)->Bool{
        if (item.objectID == nil){
            return false
        }
        
        do{
            let boundService = context?.object(with: item.objectID!)
            if (boundService?.isFault)!{
                return false
            }
            DBBoundServiceHandler.formatBoundService(src:item, target:boundService as! BoundService)
            try context?.save()
            return true
        }catch{
            Swift.print("save new bound failed")
        }
        return false
    }
    
    //delete specific bound service
    func deleteBoundService(item:NXBoundService)->Bool{
        if (item.objectID == nil){
            return false
        }
        
        let boundService = context?.object(with: item.objectID!)
        if (boundService?.isFault)!{
            return false
        }
        
        if context?.delete(boundService!) != nil {
            do{
                try context?.save()
                return true
            }catch{
                Swift.print("delete boundservice: \(item.serviceAlias) failed")
            }
        }
        return false
    }
    
    //delete all bound servie through user id
    func deleteAllBoundServiceWithUserId(userId:String)->Bool{
        let boundServiceArray:[BoundService] = getAllBSWithUserId(userId: userId)
        var isAllSuccess = true
        for item in boundServiceArray{
            if context?.delete(item) == nil{
                isAllSuccess = false
                break
            }
        }
        if isAllSuccess == true{
            do{
                try context?.save()
            }catch{
                Swift.print("delete all boundservice failed")
            }
        }
        
        return false
    }
    
    
    private func getAllBSWithUserId(userId:String)->[BoundService]{
        do{
            let request = NSFetchRequest<BoundService>(entityName: "BoundService")
            
            request.predicate = NSPredicate(format: "user_id == %@", userId)
            let result = try context!.fetch(request)
            return result
        }catch{
            Swift.print("get all boundservice failed")
        }
        return [BoundService]()
    }
    
    
    public static func formatBoundService(src:NXBoundService, target:BoundService){
        target.service_account = src.serviceAccount
        target.service_account_id = src.serviceAccountId
        target.service_account_token = src.serviceAccountToken
        target.service_alias = src.serviceAlias
        target.service_is_authed = src.serviceIsAuthed
        target.service_is_selected = src.serviceIsSelected
        target.service_type = src.serviceType
        target.user_id = src.userId
        target.repo_id = src.repoId
    }
    
    public static func formatNXBoundService(src:BoundService, target:NXBoundService){
        target.serviceAccount = src.service_account!
        target.serviceAccountId = src.service_account_id!
        target.serviceAccountToken = src.service_account_token!
        target.serviceAlias = src.service_alias!
        target.serviceIsAuthed = src.service_is_authed
        target.serviceIsSelected = src.service_is_selected
        target.serviceType = src.service_type
        target.userId = src.user_id!
        target.repoId = src.repo_id!
        target.objectID = src.objectID
    }
    
    // MARK: Fav, Off
    
    func fetchBoundService(with repoId: String, type: ServiceType?) -> BoundService? {
        let request = NSFetchRequest<BoundService>(entityName: "BoundService")
        let userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!
        
        let predict: NSPredicate = {
            if let serviceType = type?.rawValue {
                return NSPredicate(format: "repo_id == %@ && user_id == %@ && service_type == %d", repoId, userId, serviceType)
            } else {
                return NSPredicate(format: "repo_id == %@ && user_id == %@", repoId, userId)
            }
        }()
        
        request.predicate = predict
        
        let result = DBCommonUtil.fetchResult(withContext: context!, request: request)
        
        guard result.count == 1, let object = result.first else {
            return nil
        }
        
        return object
    }
    
    func fetchBoundService(withType serviceType: ServiceType) -> [NXBoundService] {
        let request = NSFetchRequest<BoundService>(entityName: "BoundService")
        let userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!
        request.predicate = NSPredicate(format: "service_type == \(serviceType.rawValue) && user_id == %@", userId)
        
        let result = DBCommonUtil.fetchResult(withContext: context!, request: request)
        
        let returnValue = result.map() {
            src -> NXBoundService in
            let target = NXBoundService()
            DBBoundServiceHandler.formatNXBoundService(src: src, target: target)
            return target
        }
        
        return returnValue
    }
    
    func fetchBoundService(with alias: String) -> BoundService? {
        let request = NSFetchRequest<BoundService>(entityName: "BoundService")
        let userId = (NXLoginUser.sharedInstance.nxlClient?.profile.userId)!
        request.predicate = NSPredicate(format: "service_alias == %@ && user_id == %@", alias, userId)
        
        let result = DBCommonUtil.fetchResult(withContext: context!, request: request)
        
        guard result.count == 1, let object = result.first else {
            return nil
        }
        
        return object
    }
    
    public static func formatBoundService(from item: NXRMCRepoItem, to bs: NXBoundService) {
        bs.repoId = item.repoId
        bs.serviceAccount = item.accountName
        bs.serviceType = item.type.rawValue
        bs.serviceAccountId = item.accountId
        bs.serviceAlias = item.name
        bs.serviceAccountToken = item.token
        if let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId {
            bs.userId = userId
        }
        bs.serviceIsSelected = false
        bs.serviceIsAuthed = false
    }
}

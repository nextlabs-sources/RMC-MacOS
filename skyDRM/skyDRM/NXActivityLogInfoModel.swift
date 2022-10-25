//
//  NXActivityLogInfoModel.swift
//  skyDRM
//
//  Created by xx-huang on 13/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

enum NXActivityLogSortType: CustomStringConvertible {
    case accessTime
    case accessResult
    
    var description: String {
        switch self {
        case .accessTime:
            return "accessTime"
            
        case .accessResult:
            return "accessResult"
        }
    }
}

enum NXActivityLogInfoSearchFieldType: CustomStringConvertible {
    case operation
    case email
    case deviceId
    
    var description: String {
        switch self {
        case .email:
            return "email"
        case .operation:
            return "operation"
        case .deviceId:
            return "deviceId"
        }
    }
}

enum OperationEnum: Int {
    case Protect = 1,Share,RemoveUser,View,Print,Download,EditSave,Revoke,Decrypt,CopyContent,CaptureScreen,Classify,Reshare,Delete
}

struct NXActivityLogInfoFilter: Queryable {
    var start: String?
    var count: String?
    var orderBy: [NXActivityLogSortType]
    var searchField: [NXActivityLogInfoSearchFieldType]
    var searchText: String
    var orderByReverse: String = "false"
    
    func createQueryItems() -> [URLQueryItem] {
        var items = [URLQueryItem]()
        
        if let start = self.start {
            let start = URLQueryItem(name: "start", value: start)
            items.append(start)
        }
        
        if let count = self.count {
            let count = URLQueryItem(name: "count", value: count)
            items.append(count)
        }
        
        let searchText = URLQueryItem(name: "searchText", value: self.searchText)
        items.append(searchText)
        
        var searchFieldOptions = ""
        for (index, option) in self.searchField.enumerated() {
            if index > 0 {
                searchFieldOptions.append(",")
            }
            searchFieldOptions.append(option.description)
        }
        
        let searchField = URLQueryItem(name: "searchField", value: searchFieldOptions)
        items.append(searchField)
        
        var sortOptions = ""
        for (index, option) in self.orderBy.enumerated() {
            if index > 0 {
                sortOptions.append(",")
            }
            sortOptions.append(option.description)
        }
        let sort = URLQueryItem(name: "orderBy", value: sortOptions)
        items.append(sort)
        
        let orderByReverse = URLQueryItem(name: "orderByReverse", value: self.orderByReverse)
        items.append(orderByReverse)
        
        return items
    }
}

class NXActivityLogInfoModel: NSObject,NSCoding {
    var email: String?
    var operation: String?
    var deviceType: String?
    var deviceId: String?
    var accessTime: TimeInterval = 0.0
    var accessResult: String?
    
    override init() {
        super.init()
    }
    
    init(withDictionary dic: [String: Any]) {
        super.init()
        setValuesForKeys(dic)
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        if key == "accessTime", let value = value {
            accessTime = (value as!TimeInterval)/1000
        }  else {
            super.setValue(value, forKey: key)
        }
    }
    
    //MARK: NSCoding
    func encode(with aCoder: NSCoder) {
        aCoder.encode(self.email, forKey: "email")
        aCoder.encode(self.operation, forKey: "operation")
        aCoder.encode(self.deviceType, forKey: "deviceType")
        aCoder.encode(self.deviceId, forKey: "deviceId")
        aCoder.encode(self.accessTime, forKey: "accessTime")
        aCoder.encode(self.accessResult, forKey: "accessResult")
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init()
        self.email = aDecoder.decodeObject(forKey: "email") as? String
        self.operation = aDecoder.decodeObject(forKey: "operation") as? String
        self.deviceType = aDecoder.decodeObject(forKey: "deviceType") as? String
        self.deviceId = aDecoder.decodeObject(forKey: "deviceId") as? String
        self.accessTime = (aDecoder.decodeObject(forKey: "accessTime") as? TimeInterval)!
        self.accessResult = aDecoder.decodeObject(forKey: "accessResult") as? String
    }
}

class NXPutActivityLogInfoRequestModel: NSObject
{
    var duid: String? = ""
    var owner: String? = ""
    var operation: Int?
    var repositoryId: String? = ""
    var filePathId: String? = ""
    var fileName: String? = ""
    var filePath: String? = ""
    var activityData: String? = ""
    var accessTime: Int = 0
    var accessResult: Int? = 0
    var userID: String? = ""
    
    override init() {
        super.init()
    }
}

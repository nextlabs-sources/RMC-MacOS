//
//  NXProjectModelA.swift
//  skyDRM
//
//  Created by pchen on 14/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXNetworkProject: NSObject {
    var projectId: String?
    var name: String?
    var projectDescription: String?
    var displayName: String?
    // MARK: as in OC, Int ... is a value type, so cannot use Int? to auto setvalue
    var creationTime: TimeInterval = 0.0
    var totalMembers: Int = 0
    var totalFiles: Int = 0
    var ownedByMe: Bool = false
    
    var owner: NXProjectOwner?
    
    var accountType: NXAccountType?
    var trialEndTime: TimeInterval = 0.0
    
    var projectMembers: [NXNetworkProjectMember]?
    
    var invitationMsg: String?
    
    override init() {
        super.init()
    }
    
    init(with dic: [String: Any]) {
        super.init()
        setValuesForKeys(dic)
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        if key == "owner", let dic = value as? [String: Any] {
            owner = NXProjectOwner(with: dic)
        } else if key == "accountType", let type = value as? String {
            accountType = NXAccountType(rawValue: type.lowercased())
        } else if key == "projectMembers",
            let dic = value as? [String: Any],
            let members = dic["members"] as? [[String: Any]] {
            projectMembers =  members.map() { NXNetworkProjectMember(with: $0) }
            
        } else {
            super.setValue(value, forKey: key)
        }
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        if key == "id", let value = value {
            projectId = "\(value)"
        } else if key == "description", let description = value as? String {
            projectDescription = description
        }
    }
}

class NXNetworkProjectMember: NSObject {
    var userId: String?
    var displayName: String?
    var email: String?
    var creationTime: TimeInterval = 0.0
    var inviterDisplayName: String?
    var inviterEmail: String?
    var avatarBase64: String?
    
    override init() {
        super.init()
    }
    
    init(with dic: [String: Any]) {
        super.init()
        
        setValuesForKeys(dic)
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        if key == "userId", let value = value {
            userId = "\(value)"
        } else if key == "creationTime", let value = value {
            creationTime = (value as!TimeInterval)/1000
        }  else {
            super.setValue(value, forKey: key)
        }
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        if key == "picture", let value = value {
            let base64Str = (value as!String).components(separatedBy: ",")
            let base64 = base64Str[1]
            
            avatarBase64 = "\(base64)"
        }
    }
    
}

class NXNetworkProjectInvitation: NSObject {
    var invitationId: String?
    var inviteeEmail: String?
    var inviterEmail: String?
    var inviterDisplayName: String?
    var inviteTime: TimeInterval = 0.0
    var code: String?
    var project: NXNetworkProject?
    
    var invitationMsg: String?
    
    override init() {
        super.init()
    }
    
    init(withDictionary dic: [String: Any]) {
        super.init()
        setValuesForKeys(dic)
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        if key == "invitationId", let value = value {
            invitationId = "\(value)"
        } else if key == "inviteTime", let value = value {
            inviteTime = (value as!TimeInterval)/1000
        } else if key == "project", let dic = value as? [String: Any] {
            project = NXNetworkProject(with: dic)
        } else {
            super.setValue(value, forKey: key)
        }
    }
    
    // if not defined, just pass
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
    }
}

enum NXListProjectType {
    case allProject
    case ownedByUser
    case userJoined
    
    var isOwnedByMe: Bool? {
        switch self {
        case .allProject:
            return nil
        case .ownedByUser:
            return true
        case .userJoined:
            return false
        }
    }
}

struct NXListProjectFilter: Queryable {
    var page: String? = nil
    var size: String? = nil
    var listProjectType: NXListProjectType = .allProject
    var listProjectOrders: [NXListProjectOrderType]
    
    init(page: String? = nil, size: String? = nil, listProjectType type: NXListProjectType, listProjectOrders orders: [NXListProjectOrderType]) {
        self.page = page
        self.size = size
        self.listProjectType = type
        self.listProjectOrders = orders
    }
    func createQueryItems() -> [URLQueryItem] {
        var items = [URLQueryItem]()
        
        if let page = page {
            items.append(URLQueryItem(name: "page", value: page))
        }
        if let size = size {
            items.append(URLQueryItem(name: "size", value: size))
        }
        if let isOwnedByMe = listProjectType.isOwnedByMe {
            items.append(URLQueryItem(name: "ownedByMe", value: "\(isOwnedByMe)"))
        }
        if listProjectOrders.isEmpty == false {
            var orderByQ = ""
            for (index, item) in listProjectOrders.enumerated() {
                if index > 0 {
                    orderByQ.append(",")
                }
                orderByQ.append(item.description)
            }
            items.append(URLQueryItem(name: "orderBy", value: orderByQ))
        }
        
        return items
    }
    
}

enum NXListProjectOrderType: CustomStringConvertible {
    case lastActionTime(isAscend: Bool)
    case name(isAscend: Bool)
    
    var description: String {
        switch self {
        case .lastActionTime(let isAscend):
            if isAscend {
                return "lastActionTime"
            }
            else {
                return "-lastActionTime"
            }
        case .name(let isAscend):
            if isAscend {
                return "name"
            }
            else {
                return "-name"
            }
        }
    }
}

enum NXProjectFileRightType: CustomStringConvertible {
    case view
    case download
    case print
    case overlay
    
    var description: String {
        switch self {
        case .view:
            return "VIEW"
        case .download:
            return "DOWNLOAD"
        case .print:
            return "PRINT"
        case .overlay:
            return "WATERMARK"
        }
    }
}

struct NXProjectUploadFileProperty {
    var rights: [NXProjectFileRightType]
    var tags: [String: Any]?
}

enum NXProjectFileSortType: CustomStringConvertible {
    case fileName(isAscend: Bool)
    case createTime(isAscend: Bool)
    
    var description: String {
        switch self {
        case .fileName(let isAscend):
            if isAscend {
                return "fileName"
            } else {
                return "-fileName"
            }
        case .createTime(let isAscend):
            if isAscend {
                return "creationTime"
            } else {
                return "-creationTime"
            }
        }
    }
}

enum NXProjectMemberSortType: CustomStringConvertible {
    case displayName(isAscend: Bool)
    case createTime(isAscend: Bool)
    
    var description: String {
        switch self {
        case .displayName(let isAscend):
            if isAscend {
                return "displayName"
            } else {
                return "-displayName"
            }
        case .createTime(let isAscend):
            if isAscend {
                return "creationTime"
            } else {
                return "-creationTime"
            }
        }
    }
}

enum NXProjectSearchFieldType: CustomStringConvertible {
    case name
    case email
    
    var description: String {
        switch self {
        case .name:
            return "name"
        case .email:
            return "email"
        }
    }
}

struct NXProjectFileFilter: Queryable {
    var page: String
    var size: String
    var orderBy: [NXProjectFileSortType]
    var pathId: String
    var qName: String?
    var searchString: String?
    
    init(page: String, size: String, orderBy: [NXProjectFileSortType],
         pathId: String, qName: String? = nil, searchString: String? = nil) {
        self.page = page
        self.size = size
        self.orderBy = orderBy
        self.pathId = pathId
        self.qName = qName
        self.searchString = searchString
    }
    
    func createQueryItems() -> [URLQueryItem] {
        var items = [URLQueryItem]()
        
        let page = URLQueryItem(name: "page", value: self.page)
        items.append(page)
        
        let size = URLQueryItem(name: "size", value: self.size)
        items.append(size)
        
        var sortOptions = ""
        for (index, option) in self.orderBy.enumerated() {
            if index > 0 {
                sortOptions.append(",")
            }
            sortOptions.append(option.description)
        }
        let sort = URLQueryItem(name: "orderBy", value: sortOptions)
        items.append(sort)
        
        let pathId = URLQueryItem(name: "pathId", value: self.pathId)
        items.append(pathId)
        
        let qName = URLQueryItem(name: "q", value: self.qName)
        items.append(qName)
        
        let searchString = URLQueryItem(name: "searchString", value: self.searchString)
        items.append(searchString)
        
        return items
    }
}

struct NXProjectMemberFilter: Queryable {
    var page: String
    var size: String
    var orderBy: [NXProjectMemberSortType]
    var picture: Bool // TODO: not use now
    var q: [NXProjectSearchFieldType]
    var searchString: String
    
    func createQueryItems() -> [URLQueryItem] {
        var items = [URLQueryItem]()
        
        let page = URLQueryItem(name: "page", value: self.page)
        items.append(page)
        
        let size = URLQueryItem(name: "size", value: self.size)
        items.append(size)
        
        var sortOptions = ""
        for (index, option) in self.orderBy.enumerated() {
            if index > 0 {
                sortOptions.append(",")
            }
            sortOptions.append(option.description)
        }
        let sort = URLQueryItem(name: "orderBy", value: sortOptions)
        items.append(sort)
        
        var searchField = ""
        for (index, option) in self.q.enumerated() {
            if index > 0 {
                searchField.append(",")
            }
            searchField.append(option.description)
        }
        let q = URLQueryItem(name: "q", value: searchField)
        items.append(q)
        
        let searchString = URLQueryItem(name: "searchString", value: self.searchString)
        items.append(searchString)
        
        let picture = URLQueryItem(name: "picture", value: "true")
        items.append(picture)
        
        return items
    }
}

struct NXProjectPendingInvitationFilter: Queryable {
    var page: String
    var size: String
    var orderBy: [NXProjectMemberSortType]
    /// only support email now
    var q: [NXProjectSearchFieldType]
    var searchString: String
    
    func createQueryItems() -> [URLQueryItem] {
        var items = [URLQueryItem]()
        
        let page = URLQueryItem(name: "page", value: self.page)
        items.append(page)
        
        let size = URLQueryItem(name: "size", value: self.size)
        items.append(size)
        
        var sortOptions = ""
        for (index, option) in self.orderBy.enumerated() {
            if index > 0 {
                sortOptions.append(",")
            }
            sortOptions.append(option.description)
        }
        let sort = URLQueryItem(name: "orderBy", value: sortOptions)
        items.append(sort)
        
        var searchField = ""
        for (index, option) in self.q.enumerated() {
            if index > 0 {
                searchField.append(",")
            }
            searchField.append(option.description)
        }
        let q = URLQueryItem(name: "q", value: searchField)
        items.append(q)
        
        let searchString = URLQueryItem(name: "searchString", value: self.searchString)
        items.append(searchString)
        
        return items
    }
}

class NXProjectFileItem: NSObject {
    var fileId: String?
    var duid: String?
    var pathId: String?
    var pathDisplay: String?
    var name: String?
    var owner: NXProjectOwner?
    
    var size: Int64?
    var isFolder: Bool = true
    var lastModified: Int64?
    var creationTime: TimeInterval?
    
    init(withDictionary dic: [String: Any]) {
        super.init()
        setValuesForKeys(dic)
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        
        if key == "size", let value = value as? Int64 {
            size = value
        } else if key == "lastModified", let value = value as? Int64 {
            lastModified = value
        } else if key == "creationTime", let value = value as? TimeInterval {
            creationTime = value
        } else if key == "id", let value = value as? String {
            fileId = value
        } else if key == "owner", let value = value as? [String: Any] {
            owner = NXProjectOwner(with: value)
        }
        else {
            super.setValue(value, forKey: key)
        }
        
    }
   
    // if not define, just pass
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        if key == "folder", let value = value as? Bool {
            isFolder = value
        }
    }
    
}

class NXProjectFileDetailItem: NSObject {
    var pathDisplay: String?
    var pathId: String?
    var name: String?
    
    var size: Int64?
    var lastModified: Int64?
    var rights: [NXRightType]?
    var isOwner: Bool?
    var isNXL: Bool?
    
    var fileType: String?
    
    init(withDictionary dic: [String: Any]) {
        super.init()
        setValuesForKeys(dic)
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        if key == "size", let value = value as? Int64 {
            size = value
        } else if key == "lastModified", let value = value as? Int64 {
            lastModified = value
        } else if key == "rights", let _ = value as? [String] {
        } else if key == "owner", let value = value as? Bool {
            isOwner = value
        } else if key == "nxl", let value = value as? Bool {
            isNXL = value
        }
        else {
            super.setValue(value, forKey: key)
        }
    }
    
    // if not define, just pass
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        if key == "nxl", let value = value as? Bool {
            isNXL = value
        }
        else if key == "owner", let value = value as? Bool {
            isOwner = value
        }
    }
}

//
//  NXMyVaultModel.swift
//  skyDRM
//
//  Created by pchen on 14/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXMyVaultDetailFileItem: NSObject {
    var name: String?
    var recipients: [String]?
    var fileLink: String?
    var protectedOn: Int64 = 0
    var sharedOn: Int64 = 0
    var rights: [NXRightType]?
    
    init(withDic dic: [String: Any]) {
        super.init()
        setValuesForKeys(dic)
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        if key == "rights", let _ = value as? [String]  {
        } else {
            super.setValue(value, forKey: key)
        }
        
    }
    
    // if not defined, just pass
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
    }
}

class NXMyVaultFileItem: NSObject {
    var pathId: String?
    var pathDisplay: String?
    var repoId: String?
    var sharedOn: Int64 = 0
    var sharedWith: String?
    var name: String?
    var duid: String?
    var isRevoked: Bool = false
    var isDeleted: Bool = false
    var isShared: Bool = false
    var size: Int64 = 0
    var customMetadata: NXMyVaultFileCustomMetadata?
    
    override init() {
        super.init()
    }
    
    init(withDic dic: [String: Any]) {
        super.init()
        setValuesForKeys(dic)
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
    
        if key == "revoked", let revoked = value as? Bool {
            self.isRevoked = revoked
            
        } else if key == "deleted", let deleted = value as? Bool {
            self.isDeleted = deleted
            
        } else if key == "shared", let shared = value as? Bool {
            self.isShared = shared
            
        } else if key == "customMetadata", let dic = value as? [String: Any] {
            customMetadata = NXMyVaultFileCustomMetadata(withDictionary: dic)
        } else {
            super.setValue(value, forKey: key)
        }

    }
    
    // if not defined, just pass
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
    }
}

struct NXMyVaultFileCustomMetadata {
    var sourceRepoName: String?
    var sourceRepoType: String?
    var sourceFilePathDisplay: String?
    var sourceFilePathId: String?
    var sourceRepoId: String?
    
    init(withDictionary dic: [String: Any]) {
        
        if let sourceRepoName = dic["SourceRepoName"] as? String {
            self.sourceRepoName = sourceRepoName
            
        }
        
        if let sourceRepoType = dic["SourceRepoType"] as? String {
            self.sourceRepoType = sourceRepoType
            
        }
        if let sourceFilePathDisplay = dic["SourceFilePathDisplay"] as? String {
            self.sourceFilePathDisplay = sourceFilePathDisplay
            
        }
        
        if let SourceFilePathId = dic["SourceFilePathId"] as? String {
            self.sourceFilePathId = SourceFilePathId
            
        }
        
        if let sourceRepoId = dic["SourceRepoId"] as? String {
            self.sourceRepoId = sourceRepoId
            
        }
    }
    
    init(sourceRepoName: String?, sourceRepoType: String?, sourceFilePathDisplay: String?,
        sourceFilePathId: String?, sourceRepoId: String?) {
        self.sourceRepoName = sourceRepoName
        self.sourceRepoType = sourceRepoType
        self.sourceFilePathDisplay = sourceFilePathDisplay
        self.sourceFilePathId = sourceFilePathId
        self.sourceRepoId = sourceRepoId
    }
}

enum NXMyVaultListSortType {
    case fileName(isAscend: Bool)
    case createTime(isAscend: Bool)
    case size(isAscend: Bool)
}

extension NXMyVaultListSortType: CustomStringConvertible {
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
        case .size(let isAscend):
            if isAscend {
                return "size"
            } else {
                return "-size"
            }
        }
    }
}

enum NXMyVaultListFilterType: String {
    case allShared
    case allFiles
    case protected
    case activedTransaction
    case deleted
    case revoked
}

struct NXMyVaultListParModel: Queryable {
    var page: String
    var size: String
    var filterType: NXMyVaultListFilterType
    var sortOptions: [NXMyVaultListSortType]
    var searchString: String?
    
    func createQueryItems() -> [URLQueryItem] {
        var items = [URLQueryItem]()
        
        let page = URLQueryItem(name: "page", value: self.page)
        items.append(page)
        
        let size = URLQueryItem(name: "size", value: self.size)
        items.append(size)
        
        let filter = URLQueryItem(name: "filter", value: self.filterType.rawValue)
        items.append(filter)
        
        var sortOptions = ""
        for (index, option) in self.sortOptions.enumerated() {
            if index > 0 {
                sortOptions.append(",")
            }
            sortOptions.append(option.description)
        }
        
        let sort = URLQueryItem(name: "orderBy", value: sortOptions)
        items.append(sort)
        
        if let str = self.searchString {
            let search = URLQueryItem(name: "q.fileName", value: str)
            items.append(search)
        }
        
        return items
    }
}

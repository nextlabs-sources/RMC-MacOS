//
//  NXSharedWithMeModel.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 14/06/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

enum NXSharedWithMeListOrderType: CustomStringConvertible {
    case name(isAscend: Bool)
    case size(isAscend: Bool)
    case sharedBy(isAscend: Bool)
    case sharedDate(isAscend: Bool)
    
    var description: String {
        switch self {
        case .name(let isAscend):
            if isAscend {
                return "name"
            } else {
                return "-name"
            }
        case .size(let isAscend):
            if isAscend {
                return "size"
            } else {
                return "-size"
            }
        case .sharedBy(let isAscend):
            if isAscend {
                return "sharedBy"
            } else {
                return "-sharedBy"
            }
        case .sharedDate(let isAscend):
            if isAscend {
                return "sharedDate"
            } else {
                return "-sharedDate"
            }
        }
    }
}

struct NXSharedWithMeListFilter: Queryable {
    var page: String
    var size: String
    var orderBy: [NXSharedWithMeListOrderType]
    var q: String?
    var searchString: String?
    
    init(page: String, size: String, orderBy: [NXSharedWithMeListOrderType],
         q: String? = nil, searchString: String? = nil) {
        self.page = page
        self.size = size
        self.orderBy = orderBy
        self.q = q
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
        
        if let q = self.q {
            let item = URLQueryItem(name: "q", value: q)
            items.append(item)
        }
        
        if let searchString = self.searchString {
            let item = URLQueryItem(name: "searchString", value: searchString)
            items.append(item)
        }
        
        return items
    }
}

class NXSharedWithMeFileItem: NSObject {
    var duid: String?
    var name: String?
    var fileType: String?
    
    var size: Int?
    var sharedDate: Int?
    
    var sharedBy: String?
    var transactionId: String?
    var transactionCode: String?
    var sharedLink: String?
    var rights: [String]?
    var comment: String?
    var isOwner: Bool = false
    
    override init() {
        super.init()
    }
    
    init(with dic: [String: Any]) {
        super.init()
        
        setValuesForKeys(dic)
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        if key == "size", let size = value as? Int {
            self.size = size
        } else if key == "sharedDate", let sharedDate = value as? Int  {
            self.sharedDate = sharedDate
        }  else {
            super.setValue(value, forKey: key)
        }
        
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        return
    }
}

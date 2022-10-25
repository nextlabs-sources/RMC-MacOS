//
//  NXRepositoryFileModel.swift
//  skyDRM
//
//  Created by pchen on 13/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXFavFileItem: NSObject {
    var pathId: String?
    var pathDisplay: String?
    var fromMyVault: Bool = false
    
    init(with dic: [String: Any]) {
        super.init()
        
        setValuesForKeys(dic)
    }
}

class NXRepoFavFileItem: NSObject {
    var repoId: String?
    var isFullCopy: Bool = false
    var markFiles: [NXFavFileItem]?
    var unmarkFiles: [NXFavFileItem]?
    
    var repoName: String?
    var repoType: String?
    
    init(with dic: [String: Any]) {
        super.init()
        setValuesForKeys(dic)
    }
    
    override func setValue(_ value: Any?, forUndefinedKey key: String) {
        if key == "markedFavoriteFiles",
            let arr = value as? [[String: Any]] {
            markFiles = arr.map() { NXFavFileItem(with: $0) }
        } else if key == "unmarkedFavoriteFiles" {
        }
    }
}

struct GetFavFilter: Queryable {
    var lastModified: String
    
    func createQueryItems() -> [URLQueryItem] {
        var items = [URLQueryItem]()
        
        let lastModified = URLQueryItem(name: "last_modified", value: self.lastModified)
        items.append(lastModified)
        
        return items
    }
}

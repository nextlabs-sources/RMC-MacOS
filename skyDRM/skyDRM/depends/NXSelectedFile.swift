//
//  NXSelectedFile.swift
//  skyDRM
//
//  Created by qchen on 2020/2/6.
//  Copyright © 2020 nextlabs. All rights reserved.
//

import Foundation

enum NXSelectedFile {
    case localFile(url: URL)
    case repositoryFile(file: NXFileBase?)
    
    var url: URL? {
        get {
            switch self {
            case .localFile(let url):
                return url
            default:
                return nil
            }
        }
    }
}

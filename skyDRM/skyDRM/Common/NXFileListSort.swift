//
//  NXFileListSort.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 4/30/20.
//  Copyright © 2020 nextlabs. All rights reserved.
//

import Foundation

enum NXListOrder: String {
    case name
    case dateModified
    case size
    case fileLocation
    case sharedWith
}

struct NXFileListSort {
    init(data: [NXFileBase]) {
        for file in data {
            if file.isFolder {
                folders.append(file)
            } else {
                files.append(file)
            }
        }
    }
    
    var files = [NXFileBase]()
    var folders = [NXFileBase]()
    
    func sort(type: NXListOrder, ascending: Bool) -> [NXFileBase] {
        return sort(files: self.folders, type: type, ascending: ascending) + sort(files: self.files, type: type, ascending: ascending)
    }
    
    private func sort(files: [NXFileBase], type: NXListOrder, ascending: Bool) -> [NXFileBase] {
        let sortedFiles: [NXFileBase]
        switch type {
        case .name:
            sortedFiles = files.sorted {
                return ascending ?($0.name.compare($1.name, options: .caseInsensitive) == .orderedAscending):($0.name.compare($1.name, options: .caseInsensitive) == .orderedDescending)
            }
        case .dateModified:
            sortedFiles = files.sorted {
                if $0.lastModifiedDate == $1.lastModifiedDate { return $0.name.localizedLowercase < $1.name.localizedLowercase}
                return itemComparator(lhs: $0.lastModifiedDate as Date, rhs: $1.lastModifiedDate as Date, ascending: ascending)
            }
        case .size:
            sortedFiles = files.sorted {
            if $0.size == $1.size { return $0.name.localizedLowercase < $1.name.localizedLowercase }
                return itemComparator(lhs: $0.size, rhs: $1.size, ascending: ascending)
            }
        case .fileLocation:
            sortedFiles = files.sorted {
           if $0.localFile == $1.localFile { return $0.name.localizedLowercase < $1.name.localizedLowercase }
                return itemComparator(lhs: $0.localFile == true ?1:0, rhs: $1.localFile == true ?1:0, ascending: ascending)
            }
        case .sharedWith:
            sortedFiles = files.sorted {
                return ($0.name.compare($1.name, options: .caseInsensitive) == .orderedAscending)
            }
        }
        return sortedFiles
    }
    
    private func itemComparator<T: Comparable>(lhs: T, rhs: T, ascending: Bool) -> Bool {
        return ascending ? (lhs < rhs) : (lhs > rhs)
    }
}

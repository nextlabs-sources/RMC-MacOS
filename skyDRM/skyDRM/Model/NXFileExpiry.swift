//
//  NXFileExpiry.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 17/07/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

enum NXExpiryType {
    case neverExpire
    case relativeExpire
    case absoluteExpire
    case rangeExpire
}

struct NXFileExpiry: CustomStringConvertible {
    
    var type: NXExpiryType
    var start: Date?
    var end: Date?
    
    fileprivate func dateToString(date: Date) -> String {
        let df = DateFormatter()
        df.dateStyle = .long
        df.timeStyle = .none
        return df.string(from: date)
    }
    
    var description: String {
        switch type {
        case .neverExpire:
            return "Never expire"
        case .relativeExpire:
            var result = "Relative expire"
            if let end = end {
                let endStr = dateToString(date:end)
                result = "FILE_RIGHT_VALIDITY_UNITIL".localized + " " + endStr
            }
            
            return result
        case .absoluteExpire:
            var result = "Absolute expire"
            if let end = end {
                let endStr = dateToString(date: end)
                result = "FILE_RIGHT_VALIDITY_UNITIL".localized + " " + endStr
            }

            return result
        case .rangeExpire:
            var result = "Range expire"
            if let start = start, let end = end {
                let startStr = dateToString(date: start)
                let endStr = dateToString(date: end)
                result = startStr + " to " + endStr
            }

            return result
        }
    }
}

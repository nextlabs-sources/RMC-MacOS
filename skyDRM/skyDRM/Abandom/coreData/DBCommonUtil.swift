//
//  DBCommonUtil.swift
//  skyDRM
//
//  Created by pchen on 22/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class DBCommonUtil {
    
    class func fetchResult<T>(withContext context: NSManagedObjectContext, request: NSFetchRequest<T>) -> [T] {
        do {
            let result = try context.fetch(request)
            return result
        } catch {
            fatalError()
        }
    }

}

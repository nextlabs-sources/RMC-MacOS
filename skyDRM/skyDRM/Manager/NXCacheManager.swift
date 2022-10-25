//
//  NXCacheManager.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 2018/8/16.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

class NXCacheManager {
    struct Constant {
        static let kLastRouter = "lastRouter"
        static let kLastTenant = "lastTenant"
        static let kRecentRouter = "recentRouter"
    }
    
    static func loadLastTenant() -> (router: String, tenant: String) {
        let router = UserDefaults.standard.string(forKey: Constant.kLastRouter) ?? ""
        let tenant = UserDefaults.standard.string(forKey: Constant.kLastTenant) ?? ""
        return (router: router.lowercased(), tenant: tenant)
    }
    
    static func saveLastTenant(router: String, tenant: String) {
        UserDefaults.standard.set(router.lowercased(), forKey: Constant.kLastRouter)
        UserDefaults.standard.set(tenant, forKey: Constant.kLastTenant)
    }
    
    static func loadRecentRouter() -> [String]? {
        let routers = UserDefaults.standard.array(forKey: Constant.kRecentRouter)
        return routers as? [String]
    }
    
    static func saveRecentRouter(router: String) {
        guard let routers = loadRecentRouter() else {
            saveRecentRouter(routers: [router])
            return
        }
        
        var result = routers
        
        for (index, value) in result.enumerated() {
            if value.lowercased() == router.lowercased() {
                result.remove(at: index)
                break
            }
        }
        
        result.insert(router, at: 0)
        saveRecentRouter(routers: result)
    }
    
    private static func saveRecentRouter(routers: [String]) {
        UserDefaults.standard.set(routers, forKey: Constant.kRecentRouter)
    }
    
}

extension NXCacheManager {
    static func clearAllUserDefaultsData(){
        let userDefaults = UserDefaults.standard
        let dics = userDefaults.dictionaryRepresentation()
        for key in dics {
            userDefaults.removeObject(forKey: key.key)
        }
        userDefaults.synchronize()
    }
}

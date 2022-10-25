//
//  NXSpecificProjectNavCellType.swift
//  skyDRM
//
//  Created by helpdesk on 3/8/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXSpecificProjectNavCellType{
    var navName:String?
    var navCount:String?
    var navImg:String?
    var shouldShowCount:Bool?
    
    init(){
        
    }
    
    init(navName: String, navCount: String, navImg: String, shouldShowCount: Bool){
        self.navName = navName
        self.navCount = navCount
        self.navImg = navImg
        self.shouldShowCount = shouldShowCount
    }
    
}

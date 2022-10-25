//
//  NXProjectFolder.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 12/09/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXProjectFolder: NXProjectFileBase {
    private var children = NSMutableArray()
    
    class func createRootFolder() -> NXFileBase {
        let root = NXFileBase()
        root.isRoot = true
        root.fullPath = "/"
        root.fullServicePath = "/"
        return root
    }
    override init(){
        super.init()
    }
    //MARK: NXFileProtocol
    override func addChild(child: NXFileBase) {
        for file in self.children {
            let fileBase = file as! NXFileBase
            if fileBase.fullServicePath == child.fullServicePath {
                self.children.remove(self.children.index(of: file))
            }
            break
        }
        self.children.add(child)
        child.parent = self
    }
    
    override func removeChild(child: NXFileBase) {
        if self.children.contains(child) {
            self.children.remove(child)
        }
    }
    
    override func removeAllChildren(){
        self.children.removeAllObjects()
    }
    
    override func getChildren() -> NSArray? {
        return self.children
    }
}

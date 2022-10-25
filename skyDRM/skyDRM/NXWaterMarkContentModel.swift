//
//  NXWaterMarkContentModel.swift
//  skyDRM
//
//  Created by Stepanoval (Xinxin) Huang on 21/04/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXWaterMarkContentModel: NSObject {
    var serialNumber: String?
    var text: String?
    var transparentRatio: Int?
    var fontName: String?
    var fontSize: Int?
    var fontColor: String?
    var isClockwise: Bool?
    var density: String?
    var isRepeat: Bool?
    
    override init() {
        super.init()
    }
    
    init(withDictionary dic: [String: Any]) {
        super.init()
        setValuesForKeys(dic)
    }
    
    override func setValue(_ value: Any?, forKey key: String) {
        if key == "repeat", let value = value {
            isRepeat = value as? Bool
        }  else {
            super.setValue(value, forKey: key)
        }
    }
}

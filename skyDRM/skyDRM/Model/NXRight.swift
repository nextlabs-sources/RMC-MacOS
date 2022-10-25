//
//  NXFileRight.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 17/07/2018.
//  Copyright © 2018 nextlabs. All rights reserved.
//

import Foundation

class NXRightObligation {
    var rights = [NXRightType]() //Set<NXRightType>()
    var watermark: NXFileWatermark?
    var expiry: NXFileExpiry?
}

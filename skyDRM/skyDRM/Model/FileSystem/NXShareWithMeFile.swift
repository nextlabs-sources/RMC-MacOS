//
//  NXShareWithMe.swift
//  skyDRM
//
//  Created by William (Weiyan) Zhao on 2019/1/2.
//  Copyright © 2019 nextlabs. All rights reserved.
//

import Foundation
import SDML
class NXShareWithMeFile: NXMyVaultFile {
    var fileType: String?
    var transactionCode: String?
    var transactionId: String?
    var shareDate: Date?
    var shareLink: String?
    var shareBy: String?
    override init() {
        super.init()
    }
}

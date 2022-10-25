//
//  Localizable.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 28/11/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

extension String {
    var localized: String {
            return NSLocalizedString(self, comment: "")
    }
}

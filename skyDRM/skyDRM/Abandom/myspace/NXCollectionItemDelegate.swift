//
//  NXCollectionItemDelegate.swift
//  skyDRM
//
//  Created by nextlabs on 08/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol NXCollectionItemDelegate : NSObjectProtocol {
    func thumbnailImageClicked(id: Int)
    func moreBtnClicked(id: Int)
    func collectionItemMouseDown()
}

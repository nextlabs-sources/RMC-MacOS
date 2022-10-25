//
//  NXScrollWheelCollectionView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/4.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Cocoa

protocol NXScrollWheelCollectionViewDelegate: NSObjectProtocol {
    func onScrollWheel(event: NSEvent)
}

class NXScrollWheelCollectionView: NSCollectionView {
    weak var scrollDelegate: NXScrollWheelCollectionViewDelegate?
    override func scrollWheel(with event: NSEvent) {
        scrollDelegate?.onScrollWheel(event: event)
    }
}

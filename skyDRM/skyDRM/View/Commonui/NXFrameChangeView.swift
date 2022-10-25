//
//  NXFrameChangeView.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/5/2.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

protocol NXFrameChangeViewDelegate: NSObjectProtocol {
    func onFrameChange(frame: NSRect)
}

class NXFrameChangeView: NSView {
    weak var frameDelegate: NXFrameChangeViewDelegate?
}

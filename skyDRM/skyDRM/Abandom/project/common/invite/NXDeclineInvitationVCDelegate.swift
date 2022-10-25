//
//  NXDeclineInvitationVCDelegate.swift
//  skyDRM
//
//  Created by Walt (Shuiping) Li on 2017/4/19.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

protocol NXDeclineInvitationVCDelegate: NSObjectProtocol {
    func onDecline(reason: String)
}

//
//  NXProjectMemberCellItemDelegate.swift
//  skyDRM
//
//  Created by xx-huang on 03/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol NXProjectMemberCellItemDelegate : NSObjectProtocol {
    func onClickMemberCellItem(memberModel:NXProjectMember?,pendingInvitation:NXProjectInvitation?, isInvitation:Bool)
}


//
//  NXProjectPendingInvitationDetailVCDelegate.swift
//  skyDRM
//
//  Created by xx-huang on 07/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol  NXProjectPendingInvitationDetailVCDelegate : NSObjectProtocol {
    func resendInvitationFinished(error:Error?)
    func revokeInvitationFinished(invitation: NXProjectInvitation, error:Error?)
}

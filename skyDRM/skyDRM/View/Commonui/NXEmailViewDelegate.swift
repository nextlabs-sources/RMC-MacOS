//
//  NXEmailViewDelegate.swift
//  skyDRM
//
//  Created by xx-huang on 06/04/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol  NXEmailViewDelegate: NSObjectProtocol{
    func emailViewTextFieldChanged()
    func checkInputTextValidity()
}

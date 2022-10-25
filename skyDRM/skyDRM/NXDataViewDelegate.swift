//
//  NXDataViewDelegate.swift
//  skyDRM
//
//  Created by Kevin on 2017/1/19.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

protocol NXDataViewDelegate : NSObjectProtocol{
    func folderClicked(folder: NXFileBase?)
    func fileClicked(file: NXFileBase)
    func selectionChanged(files:[NXFileBase])
    
    func fileOperation(type: NXFileOperation, file: NXFileBase?)
}

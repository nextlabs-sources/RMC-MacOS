//
//  NXFileInfoNormaInfolViewController.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 15/05/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXFileInfoNormaInfolViewController: NSViewController {

    @IBOutlet weak var filePath: NSTextField!
    @IBOutlet weak var fileName: NSTextField!
    @IBOutlet weak var fileSize: NSTextField!
    @IBOutlet weak var lastModified: NSTextField!
    @IBOutlet weak var originalFile: NSTextField!
    
    @IBOutlet weak var origianlFileForMyVaultView: NSStackView!
    
    var file: NXFileBase!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        settingFileInfo()
        
    }
    
    func settingFileInfo() {
        
        filePath.stringValue = "" //getFolderPath()
        fileName.stringValue = file.name
        fileName.lineBreakMode = .byTruncatingMiddle
        fileSize.stringValue = NXCommonUtils.formatFileSize(fileSize: file.size) // formatFileSizeToString(size: file.size)
        lastModified.stringValue = formatDateToString(date: file.lastModifiedDate as Date)
        
        if let myVaultFile = file as? NXNXLFile {
            origianlFileForMyVaultView.isHidden = false
            var originDisplay = ""
            if let fromService = myVaultFile.customMetadata?.sourceRepoName {
                originDisplay = fromService + " : "
            }
            if let fromDisplayPath = myVaultFile.customMetadata?.sourceFilePathDisplay {
                originDisplay += fromDisplayPath
            }
            originalFile.stringValue = originDisplay
        }else{
            origianlFileForMyVaultView.isHidden = true
        }
    }
    
    func getFolderPath() -> String {
        if ((file as? NXSharedWithMeFile) != nil) {
            return ""
        }
        
        var serviceName:String? = nil
        
        if let file = file as? NXProjectFile {
            serviceName = file.projectName
        } else {
            serviceName = file.boundService?.serviceAlias
        }

        var folderPath = ""
        if !file.fullPath.isEmpty {
            folderPath = URL(fileURLWithPath: file.fullPath).deletingLastPathComponent().path
        }
        if folderPath == "/" {
            folderPath = ""
        }
        return serviceName! + folderPath
    }
    
    func formatDateToString(date: Date) -> String {
        
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "dd MMMM yyyy, hh:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        
        let dateString = dateFormatter.string(from: date)
        
        return dateString
    }
}

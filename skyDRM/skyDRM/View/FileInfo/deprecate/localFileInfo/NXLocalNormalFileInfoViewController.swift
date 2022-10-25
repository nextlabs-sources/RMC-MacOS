//
//  NXLocalNormalFileInfoViewController.swift
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 5/26/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa

class NXLocalNormalFileInfoViewController: NSViewController {
    @IBOutlet weak var filePath: NSTextField!
    @IBOutlet weak var fileName: NSTextField!
    @IBOutlet weak var fileSize: NSTextField!
    @IBOutlet weak var lastModified: NSTextField!
    @IBOutlet weak var parseFile: NSButton!
    @IBOutlet weak var share: NSButton!
    
    var file:NXFileBase!
    var shareDisabled: Bool = true
    weak var delegate: NXLocalFileInfoActionViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do view setup here.
        
        settingFileInfo()
    }
    
    func settingFileInfo(){
        filePath.stringValue = getFolderPath()
        fileName.stringValue = file.name
        fileName.lineBreakMode = .byTruncatingMiddle
        fileSize.stringValue = NXCommonUtils.formatFileSize(fileSize: file.size)
        lastModified.stringValue = formatDataToString(date: file.lastModifiedDate as Date)
        
        
        parseFile.wantsLayer = true
        parseFile.layer?.cornerRadius = 4
        parseFile.layer?.backgroundColor = NSColor(colorWithHex: "#ffffff", alpha: 1.0)?.cgColor
        parseFile.layer?.borderColor = NSColor(colorWithHex: "#9FA3A7", alpha: 1.0)?.cgColor
        parseFile.layer?.borderWidth = 1
    
        if isNXLFile() {
            parseFile.isHidden = true
            share.isHidden = false
         
            share.wantsLayer = true
            share.layer?.backgroundColor = NSColor(colorWithHex: "#ffffff", alpha: 1.0)?.cgColor
            share.layer?.cornerRadius = 4
            share.layer?.borderColor = NSColor(colorWithHex: "#9FA3A7", alpha: 1.0)?.cgColor
            share.layer?.borderWidth = 1
            let shareString = NSLocalizedString("FILEINFO_SHARE", comment: "")
            share.title = shareString
            
            if shareDisabled {
                share.isEnabled = false
            } else {
                share.isEnabled = true
            }
        }else{
            parseFile.isHidden = true
            share.isHidden = true
        }

    }
    
    fileprivate func getFolderPath() -> String {
        var folderPath = URL(fileURLWithPath: file.fullPath).deletingLastPathComponent().path
        if folderPath == "/" {
            folderPath = "root"
        }
        return folderPath
    }
    
    fileprivate func formatDataToString(date: Date) -> String{
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "dd MMMM yyyy, hh:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        
        let dateString = dateFormatter.string(from: date)
        return dateString
    }
    
    @IBAction func parseFile(_ sender: Any) {
        delegate?.protect()
    }
    
    @IBAction func shareFile(_ sender: Any) {
        delegate?.share()
    }
    
    fileprivate func isNXLFile()->Bool{
        let fileURL = URL(fileURLWithPath: file.localPath)
        
        if (NXClient.isNXLFile(path: fileURL.path)){
            return true
        }else{
            return false
        }
    }
}

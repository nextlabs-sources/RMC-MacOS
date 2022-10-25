//
//  NXCommonUtils.swift
//  skyDRM
//
//  Created by nextlabs on 04/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation
import SystemConfiguration
import SDML

class NXCommonUtils: NSObject {
    
    struct Constant {
        static let kShowGuide = "showGuide"
    }
    
    //used for member circle view background color.
    static let circleViewBKColor = ["a":"#DD212B", "b":"#FDCB8A", "c":"#98C44A", "d":"#1A5279", "e":"#EF6645", "f":"#72CAC1", "g":"#B7DCAF", "h":"#705A9E", "i":"#FCDA04", "j":"#ED1D7C", "k":"#F7AAA5", "l":"#4AB9E6",
                                   "m":"#603A18", "n":"#88B8BC", "o":"#ECA81E", "p":"#DAACD0", "q":"#6D6E73", "r":"#9D9FA2", "s":"#9D9fA2", "t":"#B5E3EE", "u":"#BCAE9E", "v":"#C8B58E", "w":"#F8BDD2", "x":"#FED968",
                                   "y":"#F69679", "z":"#EE6769", "0":"#D3E050", "1":"#D8EBD5", "2":"#F27EA9", "3":"#1782C0", "4":"#CDECF9", "5":"#FDE9E6", "6":"#FCED95", "7":"#F99D21", "8":"#F9A85D", "9":"#BCE2D7"]
    enum downloadEventType{
        case clickFile
        case saveAsFile
        case other
    }
    
    enum renderEventSrcType{
        case local
        case project
        case myvault
        case repository
        case other
        case cache
    }
    
    fileprivate static var loginTicketCount:UInt64 = 0
    fileprivate static var loginFinishTicketCount:UInt64 = 0
//    static var waterMarkConfig:NXWaterMarkContentModel?
    
    class func updateFolderChildren( folder: NXFileBase, newFileList: NSArray){
        let addList = NSMutableArray(array: newFileList)
        let deleteList = NSMutableArray()
        var newFileBase: NXFileBase!
        
        if let children = folder.getChildren() {
            for old in children {
                let oldFile = old as! NXFileBase
                var isfind = false
                for newFile in newFileList {
                    newFileBase = newFile as? NXFileBase
                    if oldFile.fullServicePath == newFileBase.fullServicePath {
                        isfind = true
                        oldFile.lastModifiedTime = newFileBase.lastModifiedTime
                        oldFile.lastModifiedDate = newFileBase.lastModifiedDate
                        oldFile.size = newFileBase.size
                        oldFile.refreshDate = newFileBase.refreshDate
                        oldFile.isRoot = newFileBase.isRoot
                        oldFile.name = newFileBase.name
                        oldFile.serviceAlias = newFileBase.serviceAlias
                        oldFile.fullPath = newFileBase.fullPath
                        break
                    }
                }
                if false == isfind {
                    deleteList.add(oldFile)
                }
                else{
                    addList.remove(newFileBase!)
                }
            }
        }
        
        
        for file in deleteList{
            folder.removeChild(child: file as! NXFileBase)
        }
        for file in addList{
            folder.addChild(child: file as! NXFileBase)
        }
    }
    
    class func getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE, error: NSError?) -> NSError?{
        var retError: NSError?
        var domain: String!
        var description: String!
        if errorCode == .NXRMC_ERROR_NO_NETWORK {
            description = String("(\(errorCode))")
            domain = NX_ERROR_NETWORK_DOMAIN
        }
        else if errorCode == .NXRMC_ERROR_CODE_TRANS_BYTES_FAILED{
            description = String("(\(String(describing: error?.code)))")
            domain = NX_ERROR_SERVICEDOMAIN
        }
        else{
            description = String("(\(errorCode))")
            domain = NX_ERROR_SERVICEDOMAIN
        }
        
        switch (errorCode) {
        case .NXRMC_ERROR_CODE_NOSUCHFILE:
            description = NSLocalizedString("ERROR_NO_SUCH_FILE_DESC", comment: "")
        case .NXRMC_ERROR_CODE_AUTHFAILED:
            description = NSLocalizedString("ERROR_AUTH_FAILED_DESC", comment: "")
        case .NXRMC_ERROR_CODE_CONVERTFILEFAILED:
            description = NSLocalizedString("ERROR_CONVERT_FILE_FAILED_DESC", comment: "")
        case .NXRMC_ERROR_CODE_CONVERTFILE_CHECKSUM_NOTMATCHED:
            description = NSLocalizedString("ERROR_CONVERTFILE_CHECKSUM_NOTMATCHED_DESC", comment: "")
        case .NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED:
            description = NSLocalizedString("ERROR_ACCESS_UNAUTHORIZED_DESC", comment: "")
        case .NXRMC_ERROR_NO_NETWORK:
            description = NSLocalizedString("ERROR_NO_NETWORK_DESC", comment: "")
        case .NXRMC_ERROR_CODE_TRANS_BYTES_FAILED:
            description = NSLocalizedString("ERROR_URL_TRANS_FAILED", comment: "")
        case .NXRMC_ERROR_CODE_FILE_ACCESS_DENIED:
            description = NSLocalizedString("ERROR_FILE_ACCESS_DENIED", comment: "")
        default:
            description = NSLocalizedString("ERROR_UNKNOWN", comment: "")
        }
        let userInfo = [NSLocalizedDescriptionKey: description]
        retError = NSError(domain: domain, code: errorCode.rawValue, userInfo: userInfo  as [String : Any])
        return retError
    }
    
    class func getMimeType(filepath : String?) -> String? {
        guard filepath != nil else {
            return nil
        }
        var error : NSError?
        let fileExt = NXCommonUtils.getExtension(fullpath: filepath, error: &error)
        guard fileExt != nil else{
            return "application/octet-stream"
        }
        guard let uti = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension, fileExt! as NSString, nil)?.takeRetainedValue() else{
            return "application/octet-stream"
        }
        guard let mimetype = UTTypeCopyPreferredTagWithClass(uti, kUTTagClassMIMEType)?.takeRetainedValue() else {
            return "application/octet-stream"
        }
        let mimeTypeStr = mimetype as String?
        if mimeTypeStr == nil {
            if fileExt?.caseInsensitiveCompare("java") == .orderedSame {
                return "text/x-java-source"
            }
            let text = "cpp, c, h"
            if text.contains(fileExt!){
                return "texts/plain"
            }
            return "application/octet-stream"
        }
        return mimeTypeStr
    }
    
    class func is3rdRepo(node: NXFileBase) -> Bool{
        if node.boundService == nil{
            return false
        }
        return ([ServiceType.kServiceOneDrive.rawValue, ServiceType.kServiceSharepoint.rawValue, ServiceType.kServiceSharepointOnline.rawValue, ServiceType.kServiceDropbox.rawValue,
         ServiceType.kServiceGoogleDrive.rawValue] as [ServiceType.RawValue]).contains((node.boundService?.serviceType)!)
    }
    
    class func getExtension(fullpath: String?, error: inout NSError?) -> String? {
        if fullpath == nil {
            error = NSError(domain: NX_ERROR_NXLFILE_DOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE.rawValue, userInfo: nil)
            return nil
        }
        if FileManager.default.fileExists(atPath: fullpath!) == false {
            error = NSError(domain: NX_ERROR_NXLFILE_DOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE.rawValue, userInfo: nil)
            return nil
        }
        //TODO:
        
        if isNXLFile(path: fullpath!) {
            error = NSError(domain: NX_ERROR_NXLFILE_DOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NXFILE_ISNXL.rawValue, userInfo: nil)
            return nil
        }
        else{
            return (fullpath as NSString?)?.pathExtension.lowercased()
        }
    }
    
    class func randomStringwithLength(len : Int) -> String {
        let alphabet = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ123467890"
        var c = alphabet.map{String($0)}
        var s = ""
        for _ in 0..<len {
            s.append(c[Int(arc4random()) % c.count])
        }
        return s
    }
    
    class func converttoNumber(string: String?) -> NSNumber?
    {
        let f = NumberFormatter()
        f.numberStyle = .decimal
        guard let str = string else {
            return nil
        }
        let number = f.number(from: str)
        return number
    }
    
//    class func deviceID() -> String {
//
//        if let deviceID = NXLKeyChain.load(KEYCHAIN_DEVICE_ID) as? String {
//            return deviceID
//        } else {
//            let deviceID = UUID().uuidString.replacingOccurrences(of: "-", with: "")
//            NXLKeyChain.save(KEYCHAIN_DEVICE_ID, data: deviceID)
//            return deviceID
//        }
//    }
    
    class func saveOnedriveState(bExisted: Bool) {
        UserDefaults.standard.set(bExisted, forKey: KEYCHAIN_ONEDRIVE_FLAG)
    }
    
    class func loadOnedriveState() -> Bool {
        return UserDefaults.standard.bool(forKey: KEYCHAIN_ONEDRIVE_FLAG)
    }
    
    class func saveAppHasUsed(bState: Bool) {
        
            UserDefaults.standard.set(bState, forKey: KEY_FIRST_LOGIN_FLAG)
    }
    
    class func loadAppHasUsed() -> Bool {
       
       return UserDefaults.standard.bool(forKey: KEY_FIRST_LOGIN_FLAG)
    }
    
    class func loadShowGuide() -> Bool {
        return UserDefaults.standard.bool(forKey: Constant.kShowGuide)
    }
    
    class func saveShowGuide(isShow: Bool) {
        UserDefaults.standard.set(isShow, forKey: Constant.kShowGuide)
    }
    
    class func getPlatformId() ->Int{
        
        let pInfo:ProcessInfo = ProcessInfo.processInfo
        
        let operaSysVersion:OperatingSystemVersion = pInfo.operatingSystemVersion
        
        var plateFormId:Int = 300
        
        if operaSysVersion.majorVersion == 10 && ( operaSysVersion.minorVersion <= 99 && operaSysVersion.minorVersion >= 1) {
            
            plateFormId += operaSysVersion.minorVersion
        }
        return plateFormId
    }
    
    class func getTempFolder() ->URL?{
        let template = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("nextlabs/rmc", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: template.path){
            guard let _ = try? FileManager.default.createDirectory(at: template, withIntermediateDirectories: true) else {
                return nil
            }
        }
        
        let templateWithRandomFolder = template.appendingPathComponent(UUID().uuidString, isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: templateWithRandomFolder.path){
            guard let _ = try? FileManager.default.createDirectory(at: templateWithRandomFolder, withIntermediateDirectories: true) else {
                return nil
            }
        }
        
        return templateWithRandomFolder
    }
    
    class func getTmpOpenFilePath() -> URL? {
        return URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("nextlabs/rmc", isDirectory: true)
    }
    
    class func getConvertFileFolder() ->URL?{
        let template = URL(fileURLWithPath: NSTemporaryDirectory()).appendingPathComponent("nextlabs/rmc/convertFile", isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: template.path){
            guard let _ = try? FileManager.default.createDirectory(at: template, withIntermediateDirectories: true) else {
                return nil
            }
        }
        
        let templateWithRandomFolder = template.appendingPathComponent(UUID().uuidString, isDirectory: true)
        
        if !FileManager.default.fileExists(atPath: templateWithRandomFolder.path){
            guard let _ = try? FileManager.default.createDirectory(at: templateWithRandomFolder, withIntermediateDirectories: true) else {
                return nil
            }
        }
        
        Swift.print("convert file folder: \(templateWithRandomFolder)")
        
        return templateWithRandomFolder
    }
    
    //  test.docx.nxl
    class func getRandomFileName(fileExtension: String)->String{
        return UUID().uuidString + "." + fileExtension
    }
    
    class func removeTempFileAndFolder(tempPath: URL){
        let tempFolder = tempPath.deletingLastPathComponent()
        try? FileManager.default.removeItem(at: tempFolder)
    }
    
    class func createNXLFileNameWithTimeStamp(originFileName: String) ->String{
        var name = ""
        var ext = ""
        
        let range = originFileName.range(of: ".", options: .backwards)
        
        if range != nil{
            name = String(originFileName[..<(range?.lowerBound)!])
            ext = String(originFileName[(range?.lowerBound)!...])
        }else{
            name = originFileName
        }
        
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd-HH-mm-ss"
        let nowTime = Date()
        let timeString = formatter.string(from: nowTime)
        return name + "-" + timeString + ext + ".nxl"
    }
    
    class func dateFormatSyncWithWebPage(date: Date) ->String
    {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = "MM/dd/yyyy, hh:mm a"
        dateFormatter.amSymbol = "AM"
        dateFormatter.pmSymbol = "PM"
        
       return dateFormatter.string(from: date)
    }
    
    class func getDownloadLocalPath(filename: String, folderPath: String) -> String?
    {
        
        let folderUrl = URL(fileURLWithPath: folderPath, isDirectory: true)
        var filePath = folderUrl.appendingPathComponent(filename).path
        
        if FileManager.default.fileExists(atPath: folderPath) {
            var index = 1
            var renameIndex: String
            let originPath = filePath
            let range = originPath.range(of: ".", options: .backwards)
            while FileManager.default.fileExists(atPath: filePath)
            {
                renameIndex = "(\(index))"
                
                if let lowerBound = range?.lowerBound {
                    filePath = String(originPath[..<lowerBound]) + renameIndex + String(originPath[lowerBound...])
                } else {
                    filePath = originPath + renameIndex
                }
                
                index += 1
            }
        } else {
            guard
                let _ = try? FileManager.default.createDirectory(at: folderUrl, withIntermediateDirectories: true)
                else { return nil }
        }
        
        return filePath
    }
    
    class func getLocalPath(with filename: String, folderPath: String) -> String {
        let folderUrl = URL(fileURLWithPath: folderPath, isDirectory: true)
        var filePath = folderUrl.appendingPathComponent(filename).path
        
        // Filename Rule: name + " copy " + index
        // ex. "1 copy 2"
        if FileManager.default.fileExists(atPath: folderPath) {
            let originPath = filePath
            let copyStr = "copy"
            var index = 1
            
            let range = originPath.range(of: ".", options: .backwards)
            while FileManager.default.fileExists(atPath: filePath)
            {
                var nameAddtion = ""
                if index == 1 {
                    nameAddtion = " " + copyStr
                } else {
                    nameAddtion = " " + copyStr + " " + "\(index)"
                }
                
                if let lowerBound = range?.lowerBound { // has suffix
                    filePath = String(originPath[..<lowerBound]) + nameAddtion + String(originPath[lowerBound...])
                } else {
                    filePath = originPath + nameAddtion
                }
                
                index += 1
            }
        } else {
            try! FileManager.default.createDirectory(at: folderUrl, withIntermediateDirectories: true)
        }
        
        return filePath
    }
    
    class func getMainWindow() -> NSWindow{
        var mainWindow: NSWindow? = nil
        for win in NSApplication.shared.windows{
            if win.identifier!.rawValue == "mainWindow"{
                mainWindow = win
                break
            }
        }
        return mainWindow!
    }
    
    class func showNotification(title: String, content: String){
        let notification:NSUserNotification = NSUserNotification()
        notification.title = title
        notification.subtitle = ""
        notification.informativeText = content
        
        notification.soundName = NSUserNotificationDefaultSoundName
        
        notification.deliveryDate = NSDate(timeIntervalSinceNow: 0) as Date
        
        NSUserNotificationCenter.default.scheduleNotification(notification)
        
    }
    
    class func createWaitingView(superView: NSView) -> NXWaitingView?{
        var topLevelObjects:NSArray?
        if Bundle.main.loadNibNamed(NSNib.Name.init("NXWaitingView"), owner: nil, topLevelObjects: &topLevelObjects) {
            
            for item in topLevelObjects! {
                if let myView = item as? NXWaitingView{
                    superView.addSubview(myView)
                    
                    myView.frame = NSRect(x: 0, y: 0, width: superView.frame.width, height: superView.frame.height)
                    
                    return myView
                }
            }
            
        }
        
        return nil
    }
    class func createViewFromXibToScrollView(xibName: String, identifier: String, frame: NSRect?, scrollView: NSScrollView)->NSView?{
        var topLevelObjects:NSArray?
        
        if Bundle.main.loadNibNamed(NSNib.Name.init(xibName), owner: nil, topLevelObjects: &topLevelObjects) {
            for item in topLevelObjects! {
                if let myView = item as? NSView,
                    myView.identifier!.rawValue == identifier {
                    scrollView.documentView?.addSubview(myView)
                    
                    if frame != nil{
                        myView.frame = frame!
                    }else{
                        myView.frame = NSRect(x: 0, y: 0, width: scrollView.frame.width, height: scrollView.frame.height)
                    }
                    
                    
                    return myView
                }
            }
            
        }
        
        return nil
    }

    class func createViewFromXib(xibName: String, identifier: String, frame: NSRect?, superView: NSView?)-> NSView?{
        var topLevelObjects:NSArray?
        if Bundle.main.loadNibNamed(NSNib.Name.init(xibName), owner: nil, topLevelObjects: &topLevelObjects) {
            for item in topLevelObjects! {

                let myView = item as? NSView
                if myView != nil && (myView?.identifier)!.rawValue == identifier{
                    superView?.addSubview(myView!)
                
                    if frame != nil{
                        myView?.frame = frame!
                    }else{
                        myView?.frame = NSRect(x: 0, y: 0, width: (superView?.frame.width)!, height: (superView?.frame.height)!)
                    }
                    return myView
                }
            }
        }
        return nil
    }
    
    class func createToastView(xibName: String, identifier: String)->NXToastWindow?{
        
        var topLevelObjects:NSArray?
        if Bundle.main.loadNibNamed( xibName, owner: nil, topLevelObjects: &topLevelObjects) {
            for item in topLevelObjects! {
                let myWindow = item as? NXToastWindow
                if myWindow != nil && (myWindow?.identifier)!.rawValue == identifier{
                    
                    return myWindow
                }
            }
        }
        return nil
    }
    
    class func getOriginFileExtension(filename: String) -> String {
        var fileUrl = URL(fileURLWithPath: filename)
        if fileUrl.pathExtension == "nxl" {
            fileUrl.deletePathExtension()
        }
        
        return fileUrl.pathExtension.lowercased()
    }
    
    class func getFileTypeIcon(fileName: String) -> String {
        var isNxlFile = false
        var tmpName = fileName
        let nxlFileFlag = ".nxl"
        if fileName.hasSuffix(nxlFileFlag) {
            isNxlFile = true
            tmpName = String(fileName.dropLast(nxlFileFlag.count))
        }
        if tmpName.hasSuffix(".bmp") {
            return isNxlFile == true ? "bmp_protected" : "bmp"
        }
        else if tmpName.hasSuffix(".c") {
            return isNxlFile == true ? "c_protected" : "c"
        }
        else if tmpName.hasSuffix(".cpp") {
            return isNxlFile == true ? "cpp_protected" : "cpp"
        }
        else if tmpName.hasSuffix(".csv") {
            return isNxlFile == true ? "csv_protected" : "csv"
        }
        else if tmpName.hasSuffix(".doc") {
            return isNxlFile == true ? "doc_protected" : "doc"
        }
        else if tmpName.hasSuffix(".docm") {
            return isNxlFile == true ? "docm_protected" : "docm"
        }
        else if tmpName.hasSuffix(".docx") {
            return isNxlFile == true ? "docx_protected" : "docx"
        }
        else if tmpName.hasSuffix(".dotx") {
            return isNxlFile == true ? "dotx_protected" : "dotx"
        }
        else if tmpName.hasSuffix(".dwg") {
            return isNxlFile == true ? "dwg_protected" : "dwg"
        }
        else if tmpName.hasSuffix(".err") {
            return isNxlFile == true ? "err_protected" : "err"
        }
        else if tmpName.hasSuffix(".exe") {
            return isNxlFile == true ? "exe_protected" : "exe"
        }
        else if tmpName.hasSuffix(".gif") {
            return isNxlFile == true ? "gif_protected" : "gif"
        }
        else if tmpName.hasSuffix(".h") {
            return isNxlFile == true ? "h_protected" : "h"
        }
        else if tmpName.hasSuffix(".java") {
            return isNxlFile == true ? "java_protected" : "java"
        }
        else if tmpName.hasSuffix(".jpg") {
            return isNxlFile == true ? "jpg_protected" : "jpg"
        }
        else if tmpName.hasSuffix(".js") {
            return isNxlFile == true ? "js_protected" : "js"
        }
        else if tmpName.hasSuffix(".json") {
            return isNxlFile == true ? "json_protected" : "json"
        }
        else if tmpName.hasSuffix(".jt") {
            return isNxlFile == true ? "jt_protected" : "jt"
        }else if tmpName.hasPrefix(".catshape") {
            return isNxlFile == true ? "catshape_protect":"catshape"
        }
        else if tmpName.hasSuffix(".log") {
            return isNxlFile == true ? "log_protected" : "log"
        }
        else if tmpName.hasSuffix(".m") {
            return isNxlFile == true ? "m_protected" : "m"
        }
        else if tmpName.hasSuffix(".md") {
            return isNxlFile == true ? "md_protected" : "md"
        }
        else if tmpName.hasSuffix(".pdf") {
            return isNxlFile == true ? "pdf_protected" : "pdf"
        }
        else if tmpName.hasSuffix(".png") {
            return isNxlFile == true ? "png_protected" : "png"
        }
        else if tmpName.hasSuffix(".potm") {
            return isNxlFile == true ? "potm_protected" : "potm"
        }
        else if tmpName.hasSuffix(".potx") {
            return isNxlFile == true ? "potx_protected" : "potx"
        }
        else if tmpName.hasSuffix(".ppt") {
            return isNxlFile == true ? "ppt_protected" : "ppt"
        }
        else if tmpName.hasSuffix(".pptx") {
            return isNxlFile == true ? "pptx_protected" : "pptx"
        }
        else if tmpName.hasSuffix(".py") {
            return isNxlFile == true ? "py_protected" : "py"
        }else if tmpName.hasPrefix(".xmt_txt") {
            return isNxlFile == true ? "xmt_txt_protected" :"xmt_txt"
        }
        else if tmpName.hasSuffix(".rft") {
            return isNxlFile == true ? "rft_protected" : "rft"
        }
        else if tmpName.hasSuffix(".rtf") {
            return isNxlFile == true ? "rtf_protected" : "rtf"
        }
        else if tmpName.hasSuffix(".sql") {
            return isNxlFile == true ? "sql_protected" : "sql"
        }
        else if tmpName.hasSuffix(".swift") {
            return isNxlFile == true ? "swift_protected" : "swift"
        }
        else if tmpName.hasSuffix(".tif") {
            return isNxlFile == true ? "tif_protected" : "tif"
        }
        else if tmpName.hasSuffix(".txt") {
            return isNxlFile == true ? "txt_protected" : "txt"
        }
        else if tmpName.hasSuffix(".vb") {
            return isNxlFile == true ? "vb_protected" : "vb"
        }
        else if tmpName.hasSuffix(".vds") {
            return isNxlFile == true ? "vds_protected" : "vds"
        }
        else if tmpName.hasSuffix(".xls") {
            return isNxlFile == true ? "xls_protected" : "xls"
        }
        else if tmpName.hasSuffix(".xlsb") {
            return isNxlFile == true ? "xlsb_protected" : "xlsb"
        }
        else if tmpName.hasSuffix(".xlsm") {
            return isNxlFile == true ? "xlsm_protected" : "xlsm"
        }
        else if tmpName.hasSuffix(".xlsx") {
            return isNxlFile == true ? "xlsx_protected" : "xlsx"
        }else if tmpName.hasPrefix(".stl") {
            return isNxlFile == true ? "stl_protected":"stl"
            
        }else if tmpName.hasSuffix(".xlt") {
            return isNxlFile == true ? "xlt_protected" : "xlt"
        }
        else if tmpName.hasSuffix(".xltm") {
            return isNxlFile == true ? "xltm_protected" : "xltm"
        }else if tmpName.hasPrefix(".capart") {
            return isNxlFile == true ? "capart_protect" :"capart"
        }
        else if tmpName.hasSuffix(".xltx") {
            return isNxlFile == true ? "xltx_protected" : "xltx"
        }
        else if tmpName.hasSuffix(".xml") {
            return isNxlFile == true ? "xml_protected" : "xml"
        }
        else {
            return isNxlFile == true ? "default_protected" : "default"
        }
    }
    class func getCloudDriveIconForSelected(cloudDriveType: Int32)->String{
        var iconName = ""
        switch(cloudDriveType)
        {
        case ServiceType.kServiceGoogleDrive.rawValue:
            iconName = "googledrive"
            break
        case ServiceType.kServiceOneDrive.rawValue:
            iconName = "onedrive"
            break
        case ServiceType.kServiceSkyDrmBox.rawValue:
            iconName = "mydrive"
            break
        case ServiceType.kServiceDropbox.rawValue:
            iconName = "dropbox"
            break
        case ServiceType.kServiceSharepointOnline.rawValue:
            iconName = "sharepoint"
            break
        case ServiceType.kServiceMyVault.rawValue:
            iconName = "myvault"
            break
        default:
            iconName = ""
            break
        }
        
        return iconName
    }
    
    class func getCloudDriveIconForUnselected(cloudDriveType: Int32)->String{
        var iconName = ""
        switch(cloudDriveType)
        {
        case ServiceType.kServiceGoogleDrive.rawValue:
            iconName = "googledrive_grey"
            break
        case ServiceType.kServiceOneDrive.rawValue:
            iconName = "onedrive_grey"
            break
        case ServiceType.kServiceSkyDrmBox.rawValue:
            iconName = "mydrive_grey"
            break
        case ServiceType.kServiceDropbox.rawValue:
            iconName = "dropbox_grey"
            break
        case ServiceType.kServiceSharepointOnline.rawValue:
            iconName = "sharepoint_grey"
            break
        case ServiceType.kServiceMyVault.rawValue:
            iconName = "myvault_grey"
            break
        default:
            iconName = ""
            break
        }
        
        return iconName
    }
    
    class func formatFileSize(fileSize: Int64, precision: Int = 2)->String{
        let units = ["B", "KB", "MB", "GB", "TB", "PB"]
        
        var multiplyFactor = 0
        var tmp: Double = Double(fileSize)
        while (tmp >= 1024){
            tmp = tmp / 1024
            multiplyFactor += 1
        }
        
        var result = String(format: "%.\(precision)f", tmp)
        
        guard let range = result.range(of: ".") else {
            return result + units[multiplyFactor]
        }
        let end = String(result[range.lowerBound...])
        
        let endZero = String(repeating: "0", count: precision)
        if (end == ".\(endZero)"){
            result = String(result[..<range.lowerBound])
        }
        
        return result + units[multiplyFactor]
    }
    class func CalculateFileSize(fileSize: String) -> Int64 {
        let units = ["KB", "MB", "GB", "TB", "PB"]
        for (index, unit) in units.enumerated() {
            if fileSize.hasSuffix(unit) {
                let distance = unit.count * (-1)
                let endIndex = fileSize.index(fileSize.endIndex, offsetBy: distance)
                let dataStr = String(fileSize[..<endIndex])
                guard let dataFloat = Float(dataStr) else {
                    return 0
                }
                let multi = Int(pow(Double(1024), Double(index+1)))
                return Int64(dataFloat * Float(multi))
            }
        }
        if fileSize.hasSuffix("B") {
            let dataStr = String(fileSize[..<fileSize.index(before: fileSize.endIndex)])
            guard let dataInt64 = Int64(dataStr) else {
                return 0
            }
            return dataInt64
        }
        return 0
    }
    //Tom Hanks -> TH
    class func abbreviation(forUserName name:String) -> String {
        if name.isEmpty {
            return ""
        }
        let words = name.components(separatedBy: " ")
        let noemptys = words.filter { (object) -> Bool in
            return object.isEmpty == false
        }
        let firstLetters = noemptys.map { String($0.first!)}
        let size = firstLetters.count
        var letters = [String]()
        letters.append(firstLetters.first!)
        if size > 1{
            letters.append(firstLetters.last!)
        }

        return letters.joined(separator: "").uppercased()
    }
    
    //Tom Hanks -> T
    class func getStrFirstLetter(src:String)->String{
        if src.isEmpty{
            return ""
        }
        
        if let letter = src.first {
            return String(letter).uppercased()
        }else{
            return ""
        }
    }
    
    class func sequenceRights(rights: [NXRightType]?) -> [NXRightType] {
        guard let rights = rights else {
            return []
        }
        
        var fileRights = [NXRightType]()
        if rights.contains(.view) {
            fileRights.append(.view)
        }
        if rights.contains(.print) {
            fileRights.append(.print)
        }
        if rights.contains(.share) {
            fileRights.append(.share)
        }
        if rights.contains(.saveAs) {
            fileRights.append(.saveAs)
        }
        if rights.contains(.edit) {
            fileRights.append(.edit)
        }
        if rights.contains(.extract) {
            fileRights.append(.extract)
        }
        if rights.contains(.watermark) {
            fileRights.append(.watermark)
        }
        
        return fileRights
    }
    
    class func generateAttributedString(with searchTerm: String, targetString: String) -> NSAttributedString? {
        
        let attributedString = NSMutableAttributedString(string: targetString)
        do {
            let regex = try NSRegularExpression(pattern: searchTerm.trimmingCharacters(in: .whitespacesAndNewlines).folding(options: .diacriticInsensitive, locale: .current), options: .caseInsensitive)
            let range = NSRange(location: 0, length: targetString.utf16.count)
            for match in regex.matches(in: targetString.folding(options: .diacriticInsensitive, locale: .current), options: .withTransparentBounds, range: range) {
                attributedString.addAttribute(NSAttributedString.Key.font, value: NSFont.systemFont(ofSize: 13, weight: NSFont.Weight.regular), range: match.range)
                attributedString.addAttribute(NSAttributedString.Key.backgroundColor, value: NSColor.yellow, range: match.range)
            }
            return attributedString
        } catch {
            Swift.print("Error creating regular expresion: \(error)")
            return nil
        }
    }
    
    //Tip label
    class func showWarningLabel(label: NSTextField, str: String) {
        label.textColor = NSColor.red
        label.stringValue = str
        label.isHidden = false
        // Bug Fix: 44450: uncomplete in macOS 10.11
    }
    
    class func showWarningLabelNoFittingSize(label: NSTextField, str: String) {
        label.textColor = NSColor.red
        label.stringValue = str
        label.isHidden = false
    }
    
    class func showNotifyingLabel(label: NSTextField, str: String) {
        label.textColor = NSColor(red: 62/255, green: 123/255, blue: 123/255, alpha: 1.0)
        label.stringValue = str
        label.isHidden = false
        label.setFrameSize(label.fittingSize)
    }
    
    class func saveLoginState(loginState:Int32)
    {
        let userDefault = UserDefaults.standard
        userDefault.set(loginState, forKey:NXSKYDRM_LOGIN_STATE_KEY)
        userDefault.synchronize()
    }
    
    class func getCurrentLoginState() ->Int32 {
        
        let curLoginState = UserDefaults.standard.object(forKey: NXSKYDRM_LOGIN_STATE_KEY)
        guard let state = curLoginState as? Int32 else {
            return 0
        }
        return state
    }
    
    
    class func saveLocalDriveRepoId(repoId:String) {

        let router = NXClient.getCurrentClient().getTenant().0?.routerURL
        let tenantID = NXClient.getCurrentClient().getTenant().0?.tenantID
        let userID =  NXClient.getCurrentClient().getUser().0?.userID
        let suffix = "repoID"
        let key = String(format: "%@:%@:%@:%@", router!,tenantID!,userID!,suffix)

        let userDefault = UserDefaults.standard
        userDefault.set(repoId, forKey:key)
    }
    
    class func getLocalDriveRepoId() ->String {
        
        let router = NXClient.getCurrentClient().getTenant().0?.routerURL
        let tenantID = NXClient.getCurrentClient().getTenant().0?.tenantID
        let userID =  NXClient.getCurrentClient().getUser().0?.userID
        let suffix = "repoID"
        
        let key = String(format: "%@:%@:%@:%@", router!,tenantID!,userID!,suffix)
        
        let userDefault = UserDefaults.standard
        return userDefault.object(forKey: key) as! String
    }
    
    class func checkIsValidateUrl(urlString:String) -> Bool {
        let url :String?
        if urlString.hasPrefix("https://") {
            url = URL(string: urlString)?.absoluteString
        } else {
            url = URL(string: "https://" + urlString)?.absoluteString
        }
       
        if let adjustedURL = url {
            let urlRegEx = "\\bhttps?://[a-zA-Z0-9\\-.]+(?::(\\d+))?(?:(?:/[a-zA-Z0-9\\-._?,'+\\&%$=~*!():@\\\\]*)+)?"
            return NSPredicate(format: "SELF MATCHES %@", urlRegEx).evaluate(with: adjustedURL)
        }
        return false
    }
    
    static func checkIsDefaultRouter(url: String) -> Bool {
        if URL(string: url)?.host == "www.skydrm.com" {
            return true
        }
        
        return false
    }
    
    //MARK: Google drive token transition
    class func combineGoogleDriveToken(keychainName: String, persistenceString: String) -> String? {
        let flag = "^*^"
        return String.init(format: "%@%@%@", keychainName, flag, persistenceString)
    }
    class func parseGoogleDriveToken(token: String) -> [String: Any]? {
        let flag = "^*^"
        let keyOfKeyChainName = "keychainName"
        let keyOfPersistence = "persistenceString"
        let array = token.components(separatedBy: flag)
        guard array.count == 2 else {
            return nil
        }
        return [keyOfKeyChainName: array[0], keyOfPersistence: array[1]]
    }
    //MARK: Sharepoint online token transition
    class func combineSharepointOnlineToken(keychainName: String, url: String, fedAuth: String, rtFa: String) -> String? {
        let flag = "^*^"
        return String.init(format: "%@%@%@%@%@%@%@", keychainName, flag, url, flag, fedAuth, flag, rtFa)

    }
    class func parseSharepointOnlineToken(token: String) -> [String: Any]? {
        let flag = "^*^"
        let keyOfKeyChainName = "keychainName"
        let keyOfUrl = "url"
        let keyOfFedAuth = "fedAuth"
        let keyOfRtFa = "rtFa"
        let array = token.components(separatedBy: flag)
        guard array.count == 4 else {
            return nil
        }
        return [keyOfKeyChainName: array[0], keyOfUrl: array[1], keyOfFedAuth: array[2], keyOfRtFa: array[3]]
    }
    
    class func diffChanges<T: Hashable>(olds: [T], news: [T]) -> (updates: [T], adds: [T], deletes: [T]) {
        let oldSet = Set(olds)
        let newSet = Set(news)
        
        let updates = newSet.intersection(oldSet)
        let adds = newSet.subtracting(oldSet)
        let deletes = oldSet.subtracting(newSet)
        
        return (Array(updates), Array(adds), Array(deletes))
    }
    
    class func CSVStringtoData(input: [String]) -> NSData {
        var resultString = ""
        for item in input {
            resultString += item.contains(",") == true || item.contains("\"") == true
                ? "\"" + item.replacingOccurrences(of: "\"", with: "\"\"") + "\""
                : item
            resultString += ","
        }
        resultString.remove(at: resultString.index(resultString.endIndex, offsetBy: -1))
        resultString += "\n"
        
        return resultString.data(using:.utf8, allowLossyConversion: false)! as NSData
    }
    
    class func getLoginTicketCount() -> UInt64
    {
        return loginTicketCount
    }
    
    class func setLoginTicketCount()
    {
        loginTicketCount = mach_absolute_time()
    }
    
    class func getLoginFinishTicketCount() -> UInt64
    {
        return loginFinishTicketCount
    }
    
    class func setLoginFinishTicketCount()
    {
        loginFinishTicketCount = mach_absolute_time()
    }
    
    class func getCurrentRMSAddress() -> String {
        let address = UserDefaults.standard.object(forKey: NXRMS_ADDRESS_KEY)
        guard let notnilAddress = address as? String else {
            return ""
        }
        
        return notnilAddress
    }
    
    class func isNXLFile(path: String) -> Bool {
        var isNXL = false
        if FileManager.default.fileExists(atPath: path) {
            isNXL = NXClient.isNXLFile(path: path)
        } else {
            let pathExtension = URL(fileURLWithPath: path).pathExtension
            if pathExtension.lowercased() == "nxl" {
                isNXL = true
            }
        }
        
        return isNXL
    }
    
    class func connectedToNetwork() -> Bool {
        var zeroAddress = sockaddr_in()
        zeroAddress.sin_len = UInt8(MemoryLayout.size(ofValue: zeroAddress))
        zeroAddress.sin_family = sa_family_t(AF_INET)
        
        guard let defaultRouteReachability = withUnsafePointer(to: &zeroAddress, {
            $0.withMemoryRebound(to: sockaddr.self, capacity: 1) {
                SCNetworkReachabilityCreateWithAddress(nil, $0)
            }
        }) else {
            return false
        }
        
        var flags: SCNetworkReachabilityFlags = []
        if !SCNetworkReachabilityGetFlags(defaultRouteReachability, &flags) {
            return false
        }
        
        let isReachable = flags.contains(.reachable)
        let needsConnection = flags.contains(.connectionRequired)
        return (isReachable && !needsConnection)
    }

//    class func convertNXLRightsToFileRight(rights: NXLRights) -> [NXRightType] {
//        var fileRights = [NXRightType]()
//        if(rights.viewRight()) {
//            fileRights.append(.view)
//        }
//        if(rights.editRight()) {
//            fileRights.append(.edit)
//        }
//        if(rights.printRight()) {
//            fileRights.append(.print)
//        }
//        if(rights.sharingRight()) {
//            fileRights.append(.share)
//        }
//        if(rights.downloadRight()) {
//            fileRights.append(.saveAs)
//        }
//        if rights.decryptRight() {
//            fileRights.append(.extract)
//        }
//        if(!rights.getNamedObligations().isEmpty) {
//            fileRights.append(.watermark)
//        }
//        fileRights.append(.validity)
//        return fileRights
//    }
//    
//    class func convertFileRightToNXLFileRight(rights: [NXRightType]) -> NXLRights {
//        let fileRights = NXLRights()
//        if rights.isEmpty {
//            return fileRights
//        }
//        
//        fileRights.setRight(.NXLRIGHTVIEW, value: rights.contains(.view))
//        fileRights.setRight(.NXLRIGHTPRINT, value: rights.contains(.print))
//        fileRights.setRight(.NXLRIGHTSHARING, value: rights.contains(.share))
//        fileRights.setRight(.NXLRIGHTSDOWNLOAD, value: rights.contains(.saveAs))
//        fileRights.setRight(.NXLRIGHTEDIT, value: rights.contains(.edit))
//        fileRights.setObligation(.NXLOBLIGATIONWATERMARK, value: rights.contains(.watermark))
//        
//        return fileRights
//    }
    
    class func isGoogleDriveTypeFile(file: NXFileBase?) -> Bool {
        let value = file?.extraInfor[NXFileBase.Constant.kGoogleMimeType] as? String
        if value == "application/vnd.google-apps.document" ||
           value == "application/vnd.google-apps.spreadsheet" ||
           value == "application/vnd.google-apps.presentation" ||
           value == "application/vnd.google-apps.drawing" {
            return true
        }
        return false
    }
    
    class func openWebsite() {
        let path: String
        if NXClient.getCurrentClient().getUser().0?.isPersonal == true {
            path = "https://www.skydrm.com"
        } else {
            guard let url = NXClient.getCurrentClient().getTenant().0?.rmsURL else {
                NSAlert.showAlert(withMessage: "No url is available")
                return
            }
            path = url + "/login"
        }
        
        let newUrl = URL(string: path)!
        NSWorkspace.shared.open(newUrl)
    }
    
    static func createLinearGradientLayer(frame: CGRect, start: NSColor, end: NSColor) -> CALayer {
        let gradientLayer = CAGradientLayer()
        gradientLayer.colors = [start.cgColor, end.cgColor]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)
        gradientLayer.frame = frame
        
        return gradientLayer
    }
    
    static func getWatermarkDescription(from rawText: String) -> String {
        let tags: [NXWatermarkTag] = [.Date, .Email, .Time, .LineBreak]
        //remove tag characters
        var result = rawText
        for tag in tags {
            let actualText: String
            switch tag {
            case .Date:
                let now = Date()
                let formatter = DateFormatter()
                formatter.dateStyle = .full
                actualText = formatter.string(from: now)
                
            case .Email:
                let emailStr = (NXClient.getCurrentClient().getUser().0?.email) ?? ""
                actualText = emailStr
                
            case .Time:
                let now = Date()
                let formatter = DateFormatter()
                formatter.timeStyle = .full
                actualText = formatter.string(from: now)
                
            case .LineBreak:
                actualText = "\n"
            }
            
            result = result.replacingOccurrences(of: tag.rmsShortcut(), with: actualText)
        }
        
        return result
    }
    
    static func addLog(file: NXFileBase, operation: String, isAllow: Bool) {
        let userID = (NXClientUser.shared.user?.userID)!
        let date = Date()
        var type: SDMLLogOperationType = .view
        for operationType in SDMLLogOperationType.allCases {
            if operation == operationType.description {
                type = operationType
                break
            }
        }
        
        let fileDUID: String
        if let duid = file.getNXLID() {
            fileDUID = duid
        } else {
            let file = NXClient.getNXLFileInfo(localPath: file.localPath)
            fileDUID = (file?.getNXLID())!
        }
        
        let filename = file.name
        let filepath = file.localPath
        let ownerID = ""
        
        let log = SDMLActivityLog(userID: userID, type: type, isAllow: isAllow, date: date, fileDUID: fileDUID, filename: filename, filepath: filepath, ownerID: ownerID)
        
        NXClient.getCurrentClient().addLog(file: file, log: log) { (error) in
        }
    }
    
    static func isPdfFileContain3DModelFormat(path: String) -> Bool {
        guard FileManager.default.fileExists(atPath: path) else {
            return false
        }
        
        let pdfURL = CFURLCreateWithFileSystemPath(nil, path as CFString, .cfurlposixPathStyle, false)!
        let document = CGPDFDocument(pdfURL)!
        let pageNumber = document.numberOfPages
        for i in 0..<pageNumber {
            let page = document.page(at: i + 1)!
            let dict = page.dictionary!
            
            var object: CGPDFObjectRef? = nil
            if CGPDFDictionaryGetObject(dict, strdup("Annots"), &object),
                CGPDFObjectGetType(object!) == .array {
                var array: CGPDFArrayRef? = nil
                CGPDFDictionaryGetArray(dict, strdup("Annots"), &array)
                for j in 0..<CGPDFArrayGetCount(array!) {
                    var object: CGPDFObjectRef? = nil
                    if CGPDFArrayGetObject(array!, j, &object),
                        CGPDFObjectGetType(object!) == .dictionary {
                        var type: UnsafePointer<Int8>?
                        var anno: CGPDFDictionaryRef?
                        if CGPDFArrayGetDictionary(array!, j, &anno),
                            CGPDFDictionaryGetName(anno!, strdup("Subtype"), &type) {
                            if String(cString: type!) == "3D" {
                                var stream: CGPDFStreamRef?
                                if CGPDFDictionaryGetStream(anno!, strdup("3DD"), &stream) {
                                    let streamDic = CGPDFStreamGetDictionary(stream!)
                                    var typeName: UnsafePointer<Int8>?
                                    CGPDFDictionaryGetName(streamDic!, strdup("Type"), &typeName)
                                    var subTypeName: UnsafePointer<Int8>?
                                    CGPDFDictionaryGetName(streamDic!, strdup("Subtype"), &subTypeName)
                                    if String(cString: subTypeName!).caseInsensitiveCompare("U3D") == .orderedSame ||
                                        String(cString: subTypeName!).caseInsensitiveCompare("PRC") == .orderedSame {
                                        return true
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
        
        return false
    }
    
    static func searchProjectFolder(projectID: Int, fileID: String, in root: NXProjectRoot) -> (project: NXProjectModel?, isRoot: Bool, folder: NXProjectFileModel?) {
        var result: (project: NXProjectModel?, isRoot: Bool, folder: NXProjectFileModel?) = (nil, false, nil)
        for project in root.projects {
            if project.id == projectID {
                result.project = project
                
                if fileID == "" {
                    result.isRoot = true
                } else {
                    result.folder = searchProjectFolder(fileID: fileID, in: project.folders)
                }
                
                break
            }
        }
        
        return result
    }
    
    private static func searchProjectFolder(fileID: String, in folders: [NXSyncFile]) -> NXProjectFileModel? {
        var result: NXProjectFileModel? = nil
        for folder in folders {
            let projectFolder = folder.file as! NXProjectFileModel
            if projectFolder.fileId == fileID {
                result = projectFolder
                
                break
            } else {
                if projectFolder.subFolders.count > 0 {
                    if let searchResult = searchProjectFolder(fileID: fileID, in: projectFolder.subFolders) {
                        result = searchResult
                        break
                    }
                }
            }
        }
        
        return result
    }
    
    /// Upload file have no fileID, use pathID to search.
    static func searchProjectFile(fullServicePath: String, in project: NXProjectModel, result stack: inout [NXSyncFile]) -> Bool {
        var result = false
        for file in project.rootFiles {
            let projectFile = file.file as! NXProjectFileModel
            if projectFile.fullServicePath == fullServicePath {
                stack.append(file)
                result = true
                break
            }
            if projectFile.isFolder {
                stack.append(file)
                if searchProjectFile(fullServicePath: fullServicePath, in: projectFile, result: &stack) {
                    result = true
                    break
                } else {
                    stack.removeLast()
                }
            }
            
        }
        
        return result
    }
    
    private static func searchProjectFile(fullServicePath: String, in folder: NXProjectFileModel, result stack: inout [NXSyncFile]) -> Bool {
        var result = false
        for file in folder.subfiles {
            let projectFile = file.file as! NXProjectFileModel
            if projectFile.fullServicePath == fullServicePath {
                stack.append(file)
                result = true
                break
            }
            if projectFile.isFolder {
                stack.append(file)
                if searchProjectFile(fullServicePath: fullServicePath, in: projectFile, result: &stack) {
                    result = true
                    break
                } else {
                    stack.removeLast()
                }
            }
        }
        
        return result
    }
    
    static func searchOfflineFile(folder projectFolder: NXProjectFileModel) -> [NXSyncFile] {
        var result = [NXSyncFile]()
        for file in projectFolder.subfiles {
            if file.file.isOffline {
                result.append(file)
            }
        }
        
        for folder in projectFolder.subFolders {
            let subFolder = folder.file as! NXProjectFileModel
            result += searchOfflineFile(folder: subFolder)
        }
        
        return result
    }
    
    static func reserveStatus(old: [NXSyncFile], new: [NXSyncFile]) {
        for newFile in new {
            for oldFile in old {
                if newFile.file.getNXLID() == oldFile.file.getNXLID() {
                    newFile.syncStatus = oldFile.syncStatus
                    newFile.file.fileStatus = oldFile.file.fileStatus
                    break
                }
            }
        }
    }
    
    static func reserveStatus(old: NXProjectModel, new: NXProjectModel) {
        reserveProjectFileStatus(old: old.rootFiles, new: new.rootFiles)
        
        for folder in new.folders {
            let newProjectFolder = folder.file as! NXProjectFileModel
            for folder in old.folders {
                let oldProjectFolder = folder.file as! NXProjectFileModel
                if newProjectFolder.fileId == oldProjectFolder.fileId {
                    reserveStatus(old: oldProjectFolder, new: newProjectFolder)
                    break
                }
                
            }
        }
    }
    
    private static func reserveStatus(old: NXProjectFileModel, new: NXProjectFileModel) {
        reserveProjectFileStatus(old: old.subfiles, new: new.subfiles)
        
        for folder in new.subFolders {
            let newProjectFolder = folder.file as! NXProjectFileModel
            for folder in old.subFolders {
                let oldProjectFolder = folder.file as! NXProjectFileModel
                if newProjectFolder.fileId == oldProjectFolder.fileId {
                    reserveStatus(old: oldProjectFolder, new: newProjectFolder)
                    break
                }
                
            }
        }
    }
    
    private static func reserveProjectFileStatus(old: [NXSyncFile], new: [NXSyncFile]) {
        for newFile in new {
            for oldFile in old {
                if oldFile.file is NXLocalProjectFileModel {
                    continue
                }
                
                if newFile.file.getNXLID() == oldFile.file.getNXLID() {
                    newFile.syncStatus = oldFile.syncStatus
                    newFile.file.fileStatus = oldFile.file.fileStatus
                    break
                }
            }
        }
    }
    
    static func fileSize(url: String?)-> UInt64  {
        //        let paths = NSSearchPathForDirectoriesInDomains(.documentDirectory, .userDomainMask, true)
        //
        //        let pathsFile = paths[0] + url!
        let fileUrl = URL(fileURLWithPath: url!)
        
        let fileManager = FileManager.default
        do {
            let attributes = try fileManager.attributesOfItem(atPath: (fileUrl.path))
            var fileSize = attributes[FileAttributeKey.size] as! UInt64
            let dict = attributes as NSDictionary
            fileSize = dict.fileSize()
            return fileSize
        } catch let error as NSError {
            print("Something went wrong: \(error)")
            return 0
        }
    }
    
    static func resizeColumn(tableview:NSTableView,columnIndex:Int) -> CGFloat {
        var longest:CGFloat = 60 //longest cell width
        let column = tableview.tableColumns[columnIndex]
        let identifier = column.identifier
        if identifier.rawValue == "name" {
              longest  =  TABLE_COLUMN_NAME_FIXED_WIDTH
        }else if identifier.rawValue == "fileLocation"{
              longest = TABLE_COLUMN_FILELOCATION_FIXED_WIDTH
        }else if identifier.rawValue == "dateModified"{
              longest =  TABLE_COLUMN_DATEMODIFIED_FIXED_WIDTH
        }else if identifier.rawValue == "size"{
              longest = TABLE_COLUMN_SIZE_FIXED_WIDTH
        }else if identifier.rawValue == "sharedWith"{
             longest = TABLE_COLUMN_SHAREWITH_FIXED_WIDTH
        }else{
             longest = TABLE_COLUMN_SHAREWITH_FIXED_WIDTH
        }
        
        let visibleRect = tableview.visibleRect
        let rowRange = tableview.rows(in: visibleRect)
        let minRow = rowRange.location
        let maxRow = rowRange.location + rowRange.length
        
        if maxRow == 0 {
            return longest
        }
        if identifier.rawValue == "name" {
            longest = TABLE_COLUMN_NAME_FIXED_WIDTH/2
        }
        
        var maxWidth:CGFloat = 0
        for start in minRow...(maxRow-1){
            let cellView = tableview.view(atColumn:columnIndex,row: start, makeIfNecessary: true)
            if let visibleView = cellView{
                if  let view = visibleView.viewWithTag(0) as? NSTextField{
                    if maxWidth < view.frame.size.width{
                        maxWidth = view.frame.size.width
                    }
                }
                if  let view = visibleView.viewWithTag(1) as? NSTextField{
                    if maxWidth < view.frame.size.width{
                        maxWidth = view.frame.size.width
                    }
                }
                
                if  let view = visibleView.viewWithTag(2) as? NSTextField{
                    if maxWidth < view.frame.size.width{
                        maxWidth = view.frame.size.width
                    }
                }
            }
        }
        if (longest < maxWidth) {
            longest = maxWidth
        }
        if identifier.rawValue == "name"{
            longest = longest + 80
        }else{
            longest = longest + 0
        }
        return longest
    }
    
    static func getIconImage(file: NXFileBase) -> NSImage? {
        var image: NSImage?
        let fileExtension = NXCommonUtils.getOriginFileExtension(filename: file.name)
        if let type = file.status?.type, let status = file.status?.status {
            switch type {
            case .upload:
                switch status {
                case .waiting:
                    let name = "\(fileExtension)_w"
                    image = NSImage.init(named: name)
                    if image == nil {
                        image = NSImage(named: "- - -_w")
                    }
                case .pending:
                    let name = "\(fileExtension)_w"
                    image = NSImage.init(named:  name)
                    if image == nil {
                        image = NSImage(named:  "- - -_w")
                    }
                case .syncing:
                    let name = "\(fileExtension)_u"
                    image = NSImage.init(named: name)
                    if image == nil {
                        image = NSImage(named: "- - -_u")
                    }
                case .completed:
                    let name = "\(fileExtension)_d"
                    image = NSImage.init(named: name)
                    if image == nil {
                        image = NSImage(named:"- - -_d")
                    }
                case .failed:
                    let name = "\(fileExtension)_w"
                    image = NSImage.init(named: name)
                    if image == nil {
                        image = NSImage(named:  "- - -_w")
                    }
                }
                
            case .download:
                switch status {
                case.waiting:
                    let name = "\(fileExtension)_w"
                    image = NSImage.init(named:  name)
                    if image == nil {
                        image = NSImage(named: "- - -_w")
                    }

                case .pending:
                    let name = "\(fileExtension.uppercased())_G"   //_protected"
                    image = NSImage.init(named:  name)
                    if file.isFolder {
                        image = NSImage(named: NSImage.folderName )
                    }
                    if image == nil {
                        image = NSImage(named: "---_g")
                    }
                    
                case .syncing:
                    let name = "\(fileExtension)_u"
                    image = NSImage.init(named: name)
                    if image == nil {
                        image = NSImage(named: "- - -_u")
                    }
                case .completed:
                    let name = "\(fileExtension)_o"   //_protected"
                    image = NSImage.init(named: name)
                    if image == nil {
                        image = NSImage(named:"- - -_o")
                    }
                case .failed:
                    let name = "\(fileExtension)_w"
                    image = NSImage.init(named:  name)
                    if image == nil {
                        image = NSImage(named: "- - -_w")
                    }
                }
            }
        } else {
            let name = "\(fileExtension)_w"
            image = NSImage.init(named: name)
            if image == nil {
                image = NSImage(named: "- - -_w")
            }
        }
        
        return image
    }
    
    static func sort(files: [NXFileBase], type: NXListOrder, ascending: Bool) -> [NXFileBase] {
        let sort = NXFileListSort(data: files)
        return sort.sort(type: type, ascending: ascending)
    }
    
    static func search(files: [NXFile], include: String) -> [NXFile] {
        if include.isEmpty {
            return files
        } else {
            return files.filter() { $0.name.localizedCaseInsensitiveContains(include) }
        }
        
    }
    
    static func getDestinationString(file: NXFileBase) -> String {
        if let projectFile = file as? NXProjectFileModel {
            return (projectFile.project?.name)! + (projectFile.pathDisplay!)
        } else if let workspaceFile = file as? NXWorkspaceBaseFile {
            return "Workspace" + workspaceFile.fullServicePath
        }
        
        return ""
    }
    
    static func searchWorkspaceFileStack(id: String, files: [NXWorkspaceBaseFile], stack: inout [NXWorkspaceBaseFile]) -> Bool {
        for file in files {
            if file.id == id {
                stack.append(file)
                return true
            }
            
            if let subFiles = file.subWorkspaceFiles {
                stack.append(file)
                if searchWorkspaceFileStack(id: id, files: subFiles, stack: &stack) {
                    return true
                } else {
                    stack.removeLast()
                }
            }
        }
        
        return false
    }
}

// View.
extension NXCommonUtils {
    static func openPanel(parentWindow: NSWindow, allowMultiSelect: Bool = false, completion: @escaping ([URL]) -> ()) {
        let openPanel = NSOpenPanel()
        openPanel.canChooseFiles = true
        openPanel.canChooseDirectories = false
        openPanel.worksWhenModal = true
        openPanel.allowsMultipleSelection = allowMultiSelect
        openPanel.beginSheetModal(for: parentWindow) { (result) in
            if result.rawValue == NSApplication.ModalResponse.OK.rawValue {
                completion(openPanel.urls)
            }
            NotificationCenter.post(notification: .closeSelectFilePanel, object: nil, userInfo: nil)
        }
        
    }
}

extension NSIndexSet {
    func toArray() -> [Int] {
        var indexes:[Int] = []
        self.enumerate { (index, _) in
            indexes.append(index)
        }
        return indexes
    }
}

extension Dictionary where Key == NSAttributedString.Key {
    func toTypingAttributes() -> [String: Any] {
        var convertedDictionary = [String: Any]()
        
        for (key, value) in self {
            convertedDictionary[key.rawValue] = value
        }
        return convertedDictionary
    }
}
extension NXCommonUtils {
    func convertDicToStr(from: [String: Any]) -> String? {
        if let data = try? JSONSerialization.data(withJSONObject: from, options: .prettyPrinted) {
            let str = String(data: data, encoding: .utf8)
            return str
        }
        return nil
    }
}
extension NSOutlineView {
    func centreRow(row: Int, animated: Bool) {
        self.selectRowIndexes(IndexSet.init(integer: row), byExtendingSelection: false)
        let rowRect = self.frameOfCell(atColumn: 0, row: row)
        if let scrollView = self.enclosingScrollView {
            let centredPoint = NSMakePoint(0.0, rowRect.origin.y + (rowRect.size.height / 2) - ((scrollView.frame.size.height) / 2))
            if animated {
                scrollView.contentView.animator().setBoundsOrigin(centredPoint)
            } else {
                self.scroll(centredPoint)
            }
        }
    }
}

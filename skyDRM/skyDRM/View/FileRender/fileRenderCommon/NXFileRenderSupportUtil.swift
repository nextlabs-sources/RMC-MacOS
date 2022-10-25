//
//  NXFileRenderSupportUtil.swift
//  skyDRM
//
//  Created by helpdesk on 4/10/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

enum NXFileContentType {
    case NOT_SUPPORT
    case NORMAL
    case SAP3D
    case HPS3D
    case REMOTEVIEW
}

enum NXRemoteViewRenderType{
    case CANVAS
    case IMAGE
    case UNKNOWN
}

class NXFileRenderSupportUtil{
    fileprivate static let normalFileSuffix = ["htm", "html", "cpp", "txt", "h", "c", "java", "js", "xml", "pdf", "png", "jpg", "bmp", "gif", "ico", "jpeg", "tif", "tiff", "svg", "mp4", "mpeg",
                                               "audio", "3gp", "mp3", "aac", "arc", "numbers", "key", "pages", "doc", "docm", "docx", "xls", "xlsx", "ppt", "pptx", "rtf", "c", "h", "js", "xml",
                                               "log", "bmp", "m", "swift", "py", "java", "cpp", "csv", "dotx", "docm", "potm", "potx", "xltm", "xlsm", "xlt", "xltx", "vb", "err", "sql"]

    fileprivate static let hpsFileSuffix = ["jt", "prt", "sldprt", "sldasm", "catpart", "catshape", "cgr", "neu", "par",
                                            "psm", "x_b", "x_t","xmt_txt", "ipt", "igs", "stp", "step", "3dxml", "iges", "hsf","ifc","3ds","3dxml","sat","sab","_pd","model","dlv","exp",
                                            "session","CATPart","CATProduct","CATShape","CATDrawing","cgr","dae","prt",
                                            "neu","asm","xas","xpr","arc","unv","mf1","prt","pkg","ifczip","igs","iges","ipt",
                                            "iam","kmz","pdf","prc","xmt","3dm","stpz","stp.z","stl","par","asm","pwd",
                                            "psm","sldprt","sldasm","sldfpp","u3d","vda","wrl","vml","xv3","xv0","hsf","obj",nil]
    
    // for vds, some of them can be opened by rms remote viewer
    fileprivate static let remoteViewSuffix = ["vds", "vsd", "dxf", "vsdx", "dwg", "md", "xlsb","rvt","rfa","dwf","dwfx"]
    
    fileprivate static let remoteViewPrintCanvasType = ["vds"]
    fileprivate static let remoteViewPrintImageType = ["vsd", "dxf", "vsdx", "dwg", "md", "xlsb"]
    
    
    class func renderFileType(fileName name:String) -> NXFileContentType {
        let fileExtension:String
        var localURL = URL(fileURLWithPath: name)
        if localURL.pathExtension == "nxl"{
            localURL.deletePathExtension()
            fileExtension = localURL.pathExtension
        } else {
            fileExtension = localURL.pathExtension
        }
        
        if NXFileRenderSupportUtil.normalFileSuffix.contains(fileExtension.lowercased()) {
            return NXFileContentType.NORMAL
        } else if NXFileRenderSupportUtil.hpsFileSuffix.contains(fileExtension.lowercased()) {
            return NXFileContentType.HPS3D
        } else if NXFileRenderSupportUtil.remoteViewSuffix.contains(fileExtension.lowercased()) {
            return NXFileContentType.REMOTEVIEW
        } else {
            return NXFileContentType.NOT_SUPPORT
        }
    }
    
    class func judgeNXLByName(fileName: String)->Bool {
        let localURL = URL(fileURLWithPath: fileName)
        return localURL.pathExtension == "nxl"
    }
    
    class func shouldConvert(filePath: String)->Bool{
        return false
    }
    
    class func shouldRemoteView(filePath: String)->Bool{
        let fileExtension = getLocalFileExtension(localFilePath: filePath)
        return NXFileRenderSupportUtil.remoteViewSuffix.contains(fileExtension.lowercased())
    }
    
    class func shouldRemoteView(fileName: String)->Bool{
        return renderFileType(fileName: fileName) == NXFileContentType.REMOTEVIEW
    }
    
    class func isSimpleRemoteView(item: NXFileBase, renderEventSrcType: NXCommonUtils.renderEventSrcType?)->Bool{
        if renderEventSrcType != nil,
            ((item as? NXSharedWithMeFile) == nil),
            shouldRemoteView(fileName: item.name){
            if item.boundService?.serviceType != ServiceType.kServiceMyVault.rawValue,
                item.boundService?.serviceType != ServiceType.kServiceSkyDrmBox.rawValue,
                renderEventSrcType != .project{
                    return false
            }else{
                    return true
            }
        }
        
                    return false
    }
    
    class func getLocalFileExtension(localFilePath filePath:String) -> String{
        let url = URL(fileURLWithPath: filePath)
        var result = url.pathExtension
        if result == "nxl" {
            let url = url.deletingPathExtension()
            result = url.pathExtension
        }
        
        return result
    }
    
    class func getExtensionByFileName(name: String)-> String {
        var localURL = URL(fileURLWithPath: name)
        if localURL.pathExtension == "nxl"{
            localURL.deletePathExtension()
            return localURL.pathExtension
        }else{
            return localURL.pathExtension
        }
    }
    
    class func isRemoteViewUsingCanvas(localFilePath filePath:String)->NXRemoteViewRenderType{
        let fileExtension = getLocalFileExtension(localFilePath: filePath)
        if NXFileRenderSupportUtil.remoteViewPrintCanvasType.contains(fileExtension.lowercased()){
            return NXRemoteViewRenderType.CANVAS
        }else if NXFileRenderSupportUtil.remoteViewPrintImageType.contains(fileExtension.lowercased()){
            return NXRemoteViewRenderType.IMAGE
        }else{
            return NXRemoteViewRenderType.UNKNOWN
        }
    }
    
    class func isRemoteViewUsingCanvasByFileName(fileName name: String)->NXRemoteViewRenderType {
        let fileExtension = getExtensionByFileName(name: name)
        if NXFileRenderSupportUtil.remoteViewPrintCanvasType.contains(fileExtension.lowercased()){
            return NXRemoteViewRenderType.CANVAS
        } else if NXFileRenderSupportUtil.remoteViewPrintImageType.contains(fileExtension.lowercased()){
            return NXRemoteViewRenderType.IMAGE
        } else {
            return NXRemoteViewRenderType.UNKNOWN
        }
    }
    
    
    
    class func addCustomerCookie(url: URL, cookies: [String]) {
        var values = [HTTPCookie]()
        for item in cookies{
            let array = item.components(separatedBy: ";")
            
            var name = ""
            var value = ""
            var version = ""
            var path = ""
            var comment = ""
            var maximumAge = ""
            var domain = url.host!
            for temp in array{
                let tempArray = temp.components(separatedBy: "=")
                if tempArray.count == 2{
                    switch tempArray[0].lowercased() {
                    case "version":
                        version = tempArray[1]
                    case "path":
                        path = tempArray[1]
                    case " path":
                        path = tempArray[1]
                    case "PATH":
                        path = tempArray[1]
                    case "max-age":
                        maximumAge = tempArray[1]
                    case "comment":
                        comment = tempArray[1]
                    case "domain":
                        domain = url.host!
                    default:
                        name = tempArray[0]
                        value = tempArray[1]
                    }
                }
            }
            
            if maximumAge == "" {
                if let cookieProp = HTTPCookie(properties:
                    [HTTPCookiePropertyKey.name: name,
                     HTTPCookiePropertyKey.value: value,
                     HTTPCookiePropertyKey.version: "1",
                     HTTPCookiePropertyKey.discard: "YES",
                     HTTPCookiePropertyKey.comment: comment,
                     HTTPCookiePropertyKey.path: path,
                     HTTPCookiePropertyKey.domain: domain
                    ]){
                    values.append(cookieProp)
                }
            }else{
                if let cookieProp = HTTPCookie(properties:
                    [HTTPCookiePropertyKey.name: name,
                     HTTPCookiePropertyKey.value: value,
                     HTTPCookiePropertyKey.version: version,
                     HTTPCookiePropertyKey.maximumAge: maximumAge,
                     HTTPCookiePropertyKey.comment: comment,
                     HTTPCookiePropertyKey.path: path,
                     HTTPCookiePropertyKey.domain: domain
                    ]){
                    values.append(cookieProp)
                }

            }
        }
        
        HTTPCookieStorage.shared.cookieAcceptPolicy = HTTPCookie.AcceptPolicy.always
        HTTPCookieStorage.shared.setCookies(values, for: url, mainDocumentURL: nil)
    }
}

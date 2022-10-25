//
//  DownloadUploadMgr.swift
//  skyDRM
//
//  Created by Wutao (Tao) Wu on 5/19/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

struct rangeDownloadData {
    var file: NXFileBase
    var cachePath: String
}

struct downloadData {
    var file: NXFileBase
    var Path: String
    var fileSource: NXCommonUtils.renderEventSrcType
    var needOpen: Bool
}

struct uploadData {
    var srcPath: String
    var bTempNxlFile: Bool
}

protocol DownloadUploadMgrDelegate: NSObjectProtocol {
    func updateProgress(id: Int, data: Any?, progress: Float)
    func downloadUploadFinished(id: Int, data: Any?, error: NSError?)
}

class DownloadUploadMgr: NSObject {
    static let shared = DownloadUploadMgr()
    private override init(){}

    enum DownloadUploadType: Int {
        case Download
        case CacheDownload
        case Upload
    }
    
    fileprivate let serial = DispatchQueue(label: "com.skyDRM.DownloadUploadMgr")
    
    var idGenerator: Int = 0
    
    var task = [(id: Int, type: DownloadUploadType, subid: [(id: Int, delegate: DownloadUploadMgrDelegate?, data:Any?)]?, cancelled: Bool, service: Any, delegate: DownloadUploadMgrDelegate?, data: Any?)]()
    
    private func createService(bs: NXBoundService, serviceType: ServiceType) -> NXServiceOperation? {
        var service: NXServiceOperation
        switch(serviceType)
        {
        case .kServiceSkyDrmBox:
            let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket
            service = NXSkyDrmBox(withUserID: bs.userId, ticket: ticket!)
            break
        case .kServiceSharepointOnline:
            service = NXSharepointOnline(userId: bs.userId, alias: bs.serviceAlias, accessToken: bs.serviceAccountToken)
            break
        case .kServiceMyVault:
            let ticket = NXLoginUser.sharedInstance.nxlClient?.profile.ticket
            let userId = NXLoginUser.sharedInstance.nxlClient?.profile.userId
            service = MyVaultService(withUserID: userId!, ticket: ticket!)
        default:
            return nil
        }
        
        return service
    }
    
    func downloadFile(file: NXFileBase, filePath: String?, delegate: DownloadUploadMgrDelegate?, data: downloadData, forViewer: Bool = false) -> (Bool, Int) {
        var result = (false, 0)
        
        guard let bs = file.boundService,
            let serviceType = ServiceType(rawValue: bs.serviceType) else {
                return result
        }
        
        serial.sync {
            result.1 = idGenerator
            idGenerator += 1
        }
        
        if filePath == nil {
            if file.localLastModifiedDate == file.lastModifiedDate as Date,
                FileManager.default.fileExists(atPath: file.localPath) {
                    var data = data
                    data.Path = file.localPath
                
                    DispatchQueue.main.async {
                        delegate?.downloadUploadFinished(id: result.1, data: data, error: nil)
                    }
                
                    result.0 = true
                    return result
            }
            
            serial.sync {
                var bIsDownloading = false
                
                for (index, item) in task.enumerated() {
                    if item.type == .CacheDownload,
                        (item.data as! downloadData).file.boundService?.repoId == file.boundService?.repoId,
                        (item.data as! downloadData).file.fullServicePath == file.fullServicePath {
                        
                        result.0 = true
                        
                        var data = data
                        data.Path = (item.data as! downloadData).Path
                        
                        if task[index].subid == nil {
                            task[index].subid = [(result.1, delegate, data)]
                        } else {
                            task[index].subid!.append((result.1, delegate, data))
                        }
                        
                        bIsDownloading = true
                        
                        break
                    }
                }
                
                if !bIsDownloading {
                    let tempFolder = NXCommonUtils.getTempFolder()
                    guard let filePath = tempFolder?.appendingPathComponent(file.name, isDirectory: false).path else {
                        return
                    }
                    
                    if file is NXSharedWithMeFile {
                        let service = NXSharedWithMeService()
                        if service.downloadFile(file: file, to: filePath, id: result.1, forViewer: forViewer) {
                            data.file.localPath = filePath
                            data.file.convertedPath = ""
                            data.file.localLastModifiedDate = data.file.lastModifiedDate as Date

                            if DBFileBaseHandler.shared.updateFileNode(fileBase: data.file) {
                                var data = data
                                data.Path = filePath
                                task.append((result.1, .CacheDownload, nil, false, service, delegate, data))
                                
                                service.delegate = self
                                result.0 = true
                            } else {
                                service.cancelDownloadFile(id: result.1)
                            }
                        }
                        
                        return
                    }
                    
                    let service = createService(bs: bs, serviceType: serviceType)
                    
                    if service!.downloadFile(file: file,
                                             filePath: filePath,
                                             id: result.1) {
                        data.file.localPath = filePath
                        data.file.convertedPath = ""
                        data.file.localLastModifiedDate = data.file.lastModifiedDate as Date
                        if DBFileBaseHandler.shared.updateFileNode(fileBase: data.file) {
                            var data = data
                            data.Path = filePath
                            task.append((result.1, .CacheDownload, nil, false, service!, delegate, data))
                            
                            service!.setDelegate(delegate: self)
                            result.0 = true
                        } else {
                           service?.cancelDownloadOrUpload(id: result.1)
                        }
                    }
                }
            }
        } else {
            guard let dest = NXCommonUtils.getDownloadLocalPath(filename: file.name, folderPath: filePath!) else {
                return result
            }
            
            if file is NXSharedWithMeFile {
                if FileManager.default.fileExists(atPath: file.localPath) {
                    // pending
                    let service = LocalFileCopy()
                    if service.downloadFile(file: file, filePath: dest, id: result.1) {
                        var data = data
                        data.Path = dest
                        serial.sync {
                            task.append((result.1, .Download, nil, false, service, delegate, data))
                        }
                        
                        service.delegate = self
                        result.0 = true
                    }
                    
                } else {
                    let service = NXSharedWithMeService()
                    if service.downloadFile(file: file, to: dest, id: result.1, forViewer: forViewer) {
                        var data = data
                        data.Path = dest
                        serial.sync {
                            task.append((result.1, .Download, nil, false, service, delegate, data))
                        }
                        
                        service.delegate = self
                        result.0 = true
                    }
                }
                
                return result
            }
            
            var service : NXServiceOperation? = nil
            
            if file.localLastModifiedDate == file.lastModifiedDate as Date,
                FileManager.default.fileExists(atPath: file.localPath) {
                service = LocalFileCopy()
            } else {
                service = createService(bs: bs, serviceType: serviceType)
            }
            
            if service == nil {
                return result
            }
            
            if service!.downloadFile(file: file,
                                     filePath: dest,
                                     id: result.1) {
                var data = data
                data.Path = dest
                serial.sync {
                    task.append((result.1, .Download, nil, false, service!, delegate, data))
                }
            } else {
                return result
            }
            
            service!.setDelegate(delegate: self)
            result.0 = true
        }
    
        return result
    }
    
    func rangeDownloadFile(file: NXFileBase, length: Int, delegate: DownloadUploadMgrDelegate?, data: rangeDownloadData) -> (Bool, Int) {
        var result = (false, 0)
        
        guard let bs = file.boundService,
            let serviceType = ServiceType(rawValue: bs.serviceType) else {
                return result
        }
        
        let service = createService(bs: bs, serviceType: serviceType)
        if service == nil {
            return result
        }
        
        serial.sync {
            result.1 = idGenerator
            idGenerator += 1
        }
        
        let fileUrl = URL(fileURLWithPath: file.localPath)
        if file.localLastModifiedDate == file.lastModifiedDate as Date,
            FileManager.default.fileExists(atPath: file.localPath),
            let content = try? Data(contentsOf: fileUrl),
            content.count >= length {
                var data = data
                data.cachePath = file.localPath
            
                DispatchQueue.main.async {
                    delegate?.downloadUploadFinished(id: result.1, data: data, error: nil)
                }

                result.0 = true
                return result
        }
        
        let tempFolder = NXCommonUtils.getTempFolder()
        guard let filePath = tempFolder?.appendingPathComponent(NXCommonUtils.getRandomFileName(fileExtension: "nxltmp"), isDirectory: false).path else {
            return result
        }
        
        if service!.rangeDownloadFile(file: file,
                                      length: length,
                                      filePath: filePath,
                                      id: result.1) {
            var data = data
            data.cachePath = filePath
            serial.sync {
                task.append((result.1, .Download, nil, false, service!, delegate, data))
            }
        } else {
            return result
        }
        
        service!.setDelegate(delegate: self)
        
        result.0 = true
        return result
    }
    
    func uploadFile(filename: String, folder: NXFileBase, srcPath: String, fileSource: NXFileBase?, delegate: DownloadUploadMgrDelegate?, data: Any?) -> (Bool, Int) {
        var result = (false, 0)
        
        guard let bs = folder.boundService,
            let serviceType = ServiceType(rawValue: bs.serviceType) else {
                return result
        }
    
        let service = createService(bs: bs, serviceType: serviceType)
        if service == nil {
            return result
        }
        
        serial.sync {
            result.1 = idGenerator
            idGenerator += 1
        }
        
        if service!.uploadFile(filename: filename,
                              folder: folder,
                              srcPath: srcPath,
                              fileSource: fileSource,
                              id: result.1) {
            serial.sync {
                task.append((result.1, .Upload, nil, false, service!, delegate, data))
            }
        } else {
            return result
        }
        
        service!.setDelegate(delegate: self)
        
        result.0 = true
        return result
    }
    
    func cancel(id: Int) {
        serial.sync {
            for (index, item) in task.enumerated() {
                if item.id == id {
                    DispatchQueue.main.async {
                        let retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
                        item.delegate?.downloadUploadFinished(id: id, data: item.data, error: retError)
                    }
                    
                    if item.subid != nil {
                        task[index].delegate = nil
                        task[index].cancelled = true
                    } else {
                        if let service = item.service as? NXServiceOperation {
                            service.cancelDownloadOrUpload(id: item.id)
                        }
                        
                        task.remove(at: index)
                    }
                    return
                } else {
                    if item.subid != nil {
                        for (subIndex, subItem) in item.subid!.enumerated() {
                            if subItem.id == id {
                                DispatchQueue.main.async {
                                    let retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
                                    subItem.delegate?.downloadUploadFinished(id: id, data: subItem.data, error: retError)
                                }
                                
                                var subid = item.subid
                                subid?.remove(at: subIndex)
                                
                                if subid?.count == 0 {
                                    if item.cancelled {
                                        if let service = item.service as? NXServiceOperation {
                                            service.cancelDownloadOrUpload(id: item.id)
                                        }
                                        
                                        task.remove(at: index)
                                    } else {
                                        task[index].subid = nil
                                    }
                                } else {
                                    task[index].subid = subid
                                }
                                
                                return
                            }
                        }
                    }
                }
            }
        }
    }
}

extension DownloadUploadMgr: NXServiceOperationDelegate {
    func updateProgress(id: Int, progress: Float) {
        serial.sync {
            for item in task {
                if item.id == id {
                    if !item.cancelled {
                        DispatchQueue.main.async {
                            item.delegate?.updateProgress(id: id, data: item.data, progress: progress)
                        }
                    }

                    if item.subid != nil {
                        for subItem in item.subid! {
                            DispatchQueue.main.async {
                                subItem.delegate?.updateProgress(id: subItem.id, data: subItem.data, progress: progress)
                            }
                        }
                    }
                    
                    break
                }
            }
        }
    }
    
    func downloadOrUploadFinished(id: Int, error: NSError?) {
        serial.sync {
            for (index, item) in task.enumerated() {
                if item.id == id {
                    if !item.cancelled {
                        if let data = item.data as? downloadData {
                            tryUpdateFileAfterDownload(file: data.file)
                        }
                        DispatchQueue.main.async {
                            item.delegate?.downloadUploadFinished(id: id, data: item.data, error: error)
                        }
                    }
                    
                    if item.subid != nil {
                        for subItem in item.subid! {
                            DispatchQueue.main.async {
                                subItem.delegate?.downloadUploadFinished(id: subItem.id, data: subItem.data, error: error)
                            }
                        }
                    }
                    
                    task.remove(at: index)
                    break
                }
            }
        }
    }
    
    private func tryUpdateFileAfterDownload(file: NXFileBase) {
        if let exportExtension = file.extraInfor[NXFileBase.Constant.kGoogleExportExtension] as? String {
            if !file.localPath.hasSuffix(exportExtension) {
                file.localPath = file.localPath.appending(exportExtension)
                _ = DBFileBaseHandler.shared.updateFileNode(fileBase: file)
            }
        }
    }
}

extension DownloadUploadMgr {
    class LocalFileCopy: NSObject, NXServiceOperation {
        weak var delegate: NXServiceOperationDelegate?
        
        private let serial = DispatchQueue(label: "com.skyDRM.DownloadUploadMgr.LocalFileCopy", attributes: .concurrent)
        
        private var downloadOrUploadId : Int? = nil
        private var cancelled : Bool = false
        
        func getFiles(folder: NXFileBase) -> Bool {
            return false
        }
        
        func getAllFilesInFolder(folder: NXFileBase) -> Bool  {
            return false
        }
        
        func getMetaData(file: NXFileBase) -> Bool {
            return false
        }
        
        func deleteFileFolder(file: NXFileBase) -> Bool {
            return false
        }
        
        func uploadFile(filename: String, folder: NXFileBase, srcPath: String, fileSource: NXFileBase?, id: Int) -> Bool {
            return false
        }
        
        func updateFile(srcPath: String, dstFile: NXFileBase) -> Bool {
            return false
        }
        
        func cancelUpdateFile(srcPath: String, dstFile: NXFileBase) -> Bool {
            return false
        }
        
        func downloadFile(file: NXFileBase, filePath: String, id: Int) -> Bool {
            serial.async {
                var fileSize : UInt64 = 0
                
                do {
                    let attr : NSDictionary? = try FileManager.default.attributesOfItem(atPath: file.localPath) as NSDictionary?
                    
                    if let _attr = attr {
                        fileSize = _attr.fileSize();
                    }
                } catch {
                    let retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_FILE_ACCESS_DENIED.rawValue, userInfo: nil)
                    self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: retError)
                    return
                }
                
                let fpSource = fopen((file.localPath as NSString).utf8String, "r")
                if fpSource == nil {
                    let retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_FILE_ACCESS_DENIED.rawValue, userInfo: nil)
                    self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: retError)
                    return
                }
                
                let fpDestination = fopen((filePath as NSString).utf8String, "w")
                
                if fpDestination == nil {
                    fclose(fpSource)
                    let retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_FILE_ACCESS_DENIED.rawValue, userInfo: nil)
                    self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: retError)
                    return
                }
                
                var buffer: [UInt8] = Array<UInt8>(repeating: 0, count: 1024)
                var hasReadLength : UInt64 = 0
                
                while true {
                    let fReadLength = fread(&buffer, 1, 1024, fpSource)
                    fwrite(buffer, 1, fReadLength, fpDestination)
                    if self.cancelled || fReadLength == 0 || feof(fpSource) != 0 {
                        break
                    }
                    
                    hasReadLength += UInt64(fReadLength)
                    self.delegate?.updateProgress?(id: self.downloadOrUploadId!, progress: Float(hasReadLength) / Float(fileSize))
                }
                
                fclose(fpSource)
                fclose(fpDestination)
                
                if self.cancelled {
                    let retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
                    self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: retError)
                } else {
                    self.delegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: nil)
                }
            }
            
            downloadOrUploadId = id
            
            return true
        }
        
        func rangeDownloadFile(file: NXFileBase, length: Int, filePath: String, id: Int) -> Bool {
            return false
        }
        
        func cancelDownloadOrUpload(id: Int) {
            guard downloadOrUploadId == id else {
                return
            }
            
            cancelled = true
        }
        
        func setDelegate(delegate: NXServiceOperationDelegate) {
            self.delegate = delegate
        }
        
        func isProgressSupported() -> Bool {
            return true
        }
        
        func cancelGetFiles(folder: NXFileBase) -> Bool {
            return false
        }
        
        func addFolder(folderName: String, parentFolder: NXFileBase) -> Bool {
            return false
        }
        
        func cancelGetMetaData(file: NXFileBase) -> Bool {
            return false
        }
        
        func setAlias(alias: String) {
        }
        
        func getServiceAlias() -> String {
            return ""
        }
        
        func getUserInfo() -> Bool {
            return false
        }
        
        func cancelGetUserInfo() -> Bool {
            return false
        }
    }
}

extension DownloadUploadMgr: NXSharedWithMeServiceDelegate {
    
    func downloadProgress(id: Int, progress: Float) {
        serial.sync {
            for item in task {
                if item.id == id {
                    if !item.cancelled {
                        item.delegate?.updateProgress(id: id, data: item.data, progress: progress)
                    }
                    
                    if item.subid != nil {
                        for subItem in item.subid! {
                            subItem.delegate?.updateProgress(id: subItem.id, data: subItem.data, progress: progress)
                        }
                    }
                    
                    break
                }
            }
        }
    }
    
    func downloadFileFinish(id: Int, error: Error?) {
        serial.sync {
            for (index, item) in task.enumerated() {
                if item.id == id {
                    if !item.cancelled {
                        item.delegate?.downloadUploadFinished(id: id, data: item.data, error: error as NSError?)
                    }
                    
                    if item.subid != nil {
                        for subItem in item.subid! {
                            subItem.delegate?.downloadUploadFinished(id: subItem.id, data: subItem.data, error: error as NSError?)
                        }
                    }
                    
                    task.remove(at: index)
                    break
                }
            }
        }
    }
}

//
//  NSSharepointOnline.swift
//  skyDRM
//
//  Created by nextlabs on 03/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class NXSharepointOnline : NSObject, NXServiceOperation, NXSharePointManagerDelegate
{
    private var userId = String()
    private var alias = String()
    private var sharepointManager: NXSharePointManager?
    private var enumFolderStack = NSMutableArray()
    private var getMetaDataDictionary = NSMutableDictionary()
    private var updateLocalPathDictionary = NSMutableDictionary()
    weak var delegate: NXServiceOperationDelegate?
    var isLinked = false
    
    private var fullServicePath : String? = nil
    private var downloadPath : String? = nil
    private var rangeDownloadPath : String? = nil
    private var uploadFileName : String? = nil
    private var uploadSrcPath : String? = nil
    private var downloadOrUploadId : Int? = nil
    
    private static let KEY_TYPE = "Type"
    private static let KEY_SITE = "SiteUrl"
    private static let KEY_RELATIVE = "RelativeUrl"
    
    private enum SPNodeType: Int {
        case Site
        case Folder
        case File
        case Unknown
    }
    
    init(userId: String, alias: String, accessToken: String) {
        super.init()
        self.userId = userId
        self.alias = alias
        guard let property = NXCommonUtils.parseSharepointOnlineToken(token: accessToken),
        let keychain = property["keychainName"] as? String else {
            return
        }
        if let sp = NXSPAuthViewController.auth(fromKeychain: keychain){
            Swift.print("SharepointOnline Authentication succeeded")
            self.sharepointManager = sp
            self.sharepointManager?.delegate = self
            isLinked = true
        }
        else{
            Swift.print("SharepointOnline Authentication failed")
        }
    }
    
    //MARK: NXServiceOperation
    func getFiles(folder: NXFileBase) -> Bool {
        guard isLinked == true,
            folder is NXFolder else {
            return false
        }
        if folder.isRoot {
            folder.fullPath = "/"
            guard let site = self.sharepointManager?.siteURL else {
                return false
            }
            let dic = compositeServicePath(type: .Site, site: site)
            guard let fullServicePath = convertDictionary2Json(dic: dic) else{
                return false
            }
            folder.fullServicePath = fullServicePath
        }
        
        guard let dic = convertJson2Dictionary(json: folder.fullServicePath) else {
            return false
        }
        guard let typeValue = dic[NXSharepointOnline.KEY_TYPE] as! Int?,
            let type = SPNodeType(rawValue: typeValue),
            let site = dic[NXSharepointOnline.KEY_SITE] as! String? else {
            return false
        }
        
        if type == .Folder {
            guard let relativeUrl = dic[NXSharepointOnline.KEY_RELATIVE] as! String? else {
                return false
            }
            self.sharepointManager?.allChildItemsInFolder(withSite: site, folderPath: relativeUrl)
        }
        else{
            self.sharepointManager?.allChildItems(withSite: site)
        }
        self.enumFolderStack.add(folder)
        return true
    }
    
    func getAllFilesInFolder(folder: NXFileBase) -> Bool {
        return false
    }
    
    func cancelGetFiles(folder: NXFileBase) -> Bool {
        return false
    }
    
    func downloadFile(file: NXFileBase, filePath: String, id: Int) -> Bool {
        guard isLinked == true,
            file is NXFile else {
            return false
        }

        guard let dic = convertJson2Dictionary(json: file.fullServicePath) else {
            return false
        }
        
        guard let site = dic[NXSharepointOnline.KEY_SITE] as! String?,
            let relativePath = dic[NXSharepointOnline.KEY_RELATIVE] as! String? else {
                return false
        }
        
        sharepointManager?.downloadFile(withSite: site, filePath: relativePath, destPath: filePath)
        
        fullServicePath = file.fullServicePath
        downloadPath = filePath
        downloadOrUploadId = id
        
        return true
    }
    
    func rangeDownloadFile(file: NXFileBase, length: Int, filePath: String, id: Int) -> Bool {
        guard isLinked == true,
            file is NXFile else {
                return false
        }
        
        guard let dic = convertJson2Dictionary(json: file.fullServicePath) else {
            return false
        }
        
        guard let site = dic[NXSharepointOnline.KEY_SITE] as? String,
            let relativePath = dic[NXSharepointOnline.KEY_RELATIVE] as? String else {
                return false
        }
        
        let range = NSMakeRange(0, length)
        sharepointManager?.downloadFile(withSite: site, filePath: relativePath, range: range)
        
        fullServicePath = file.fullServicePath
        rangeDownloadPath = filePath
        downloadOrUploadId = id
        
        return true
    }
    
    func deleteFileFolder(file: NXFileBase) -> Bool {
        guard isLinked == true else {
            return false
        }
        guard let dic = convertJson2Dictionary(json: file.fullServicePath) else {
            return false
        }
        guard let typeValue = dic[NXSharepointOnline.KEY_TYPE] as! Int?,
            let type = SPNodeType(rawValue: typeValue),
            let site = dic[NXSharepointOnline.KEY_SITE] as! String? else {
                return false
        }
        switch type {
        case .Site:
            return false
        case .Folder:
            guard let folderUrl = dic[NXSharepointOnline.KEY_RELATIVE] as! String? else {
                return false
            }
            sharepointManager?.deleteFolderOrDocumentlib(withSite: site, relativePath: folderUrl)
            return true
        case .File:
            guard let fileUrl = dic[NXSharepointOnline.KEY_RELATIVE] as! String? else {
                return false
            }
            sharepointManager?.deleteFile(withSite: site, filePath: fileUrl)
            return true
        default:
            break
        }
        return false
    }
    
    func addFolder(folderName: String, parentFolder: NXFileBase) -> Bool {
        guard isLinked == true else {
            return false
        }
        guard let dic = convertJson2Dictionary(json: parentFolder.fullServicePath) else {
            return false
        }
        guard let typeValue = dic[NXSharepointOnline.KEY_TYPE] as! Int?,
            let type = SPNodeType(rawValue: typeValue),
            let site = dic[NXSharepointOnline.KEY_SITE] as! String? else {
                return false
        }
        switch type {
        case .Site:
            sharepointManager?.createDocumentLib(withSite: site, documentLibName: folderName)
            return true
        case .Folder:
            guard let folderUrl = dic[NXSharepointOnline.KEY_RELATIVE] as! String? else {
                return false
            }
            sharepointManager?.createFolder(withSite: site, folderName: folderName, parentPath: folderUrl)
            return true
        default:
            break
        }
        return false
    }
    
    func uploadFile(filename: String, folder: NXFileBase, srcPath: String, fileSource: NXFileBase? = nil, id: Int) -> Bool {
        guard isLinked == true else {
            return false
        }
        
        guard folder.isRoot == false else {
            return false
        }
        
        guard let dic = convertJson2Dictionary(json: folder.fullServicePath) else {
            return false
        }
        
        guard let typeValue = dic[NXSharepointOnline.KEY_TYPE] as! Int?,
            let type = SPNodeType(rawValue: typeValue),
            let site = dic[NXSharepointOnline.KEY_SITE] as! String? else {
            return false
        }
        
        if type != .Folder {
            return false
        }
        
        guard let folderUrl = dic[NXSharepointOnline.KEY_RELATIVE] as! String? else {
            return false
        }
        
        sharepointManager?.addFile(withSite: site, fileName: filename, folderPath: folderUrl, localPath: srcPath)
        
        fullServicePath = folder.fullServicePath
        uploadFileName = filename
        uploadSrcPath = srcPath
        downloadOrUploadId = id
        
        return true
    }
    
    func cancelDownloadOrUpload(id: Int) {
        guard isLinked == true,
        downloadOrUploadId == id else {
            return
        }
        
        guard let sharepointManager = sharepointManager,
            let dic = convertJson2Dictionary(json: fullServicePath!),
            let site = dic[NXSharepointOnline.KEY_SITE] as? String,
            let filePath = dic[NXSharepointOnline.KEY_RELATIVE] as? String else {
                return
        }
        
        if downloadPath != nil {
            sharepointManager.cancelDownloadFile(withSite: site, filePath: filePath, destPath: downloadPath)
        }
        
        if rangeDownloadPath != nil {
            sharepointManager.cancelRangeDownloadFile(withSite: site, filePath: filePath)
        }
        
        if uploadSrcPath != nil {
            sharepointManager.cancelAddFile(withSite: site, fileName: uploadFileName, folderPath: filePath, localPath: uploadSrcPath)
        }
    }
    
    func updateFile(srcPath: String, dstFile: NXFileBase) -> Bool {
        guard isLinked == true else {
            return false
        }
        guard let dic = convertJson2Dictionary(json: dstFile.fullServicePath) else {
            return false
        }
        guard let typeValue = dic[NXSharepointOnline.KEY_TYPE] as? Int,
            let type = SPNodeType(rawValue: typeValue),
            let site = dic[NXSharepointOnline.KEY_SITE] as? String else {
                return false
        }
        if type != .File {
            return false
        }
        guard let fileUrl = dic[NXSharepointOnline.KEY_RELATIVE] as? String else {
            return false
        }
        let key = getUpdateTicketKey(srcPath: srcPath, dstFile: dstFile)
        updateLocalPathDictionary.setObject(srcPath, forKey: key as NSCopying)
        sharepointManager?.updateFile(withSite: site, filePath: fileUrl, localPath: srcPath)
        return true
    }
    
    func cancelUpdateFile(srcPath: String, dstFile: NXFileBase) -> Bool {
        guard let sharepointManager = sharepointManager,
            let dic = convertJson2Dictionary(json: dstFile.fullServicePath),
            let srcPath = updateLocalPathDictionary.object(forKey: dstFile.fullServicePath) as? String,
            let site = dic[NXSharepointOnline.KEY_SITE] as? String,
            let fileUrl = dic[NXSharepointOnline.KEY_RELATIVE] as? String else {
                return false
        }
        let key = getUpdateTicketKey(srcPath: srcPath, dstFile: dstFile)
        updateLocalPathDictionary.removeObject(forKey: key)
        return sharepointManager.cancelUpdateFile(withSite: site, filePath: fileUrl, localPath: srcPath)
    }
    
    func getMetaData(file: NXFileBase) -> Bool {
        guard isLinked == true else {
            return false
        }
        guard let dic = convertJson2Dictionary(json: file.fullServicePath) else {
            return false
        }
        guard let typeValue = dic[NXSharepointOnline.KEY_TYPE] as! Int?,
            let type = SPNodeType(rawValue: typeValue),
            let site = dic[NXSharepointOnline.KEY_SITE] as! String? else {
                return false
        }
        switch type {
        case .Site:
            sharepointManager?.getSiteMetaData(withSite: site)
        case .Folder:
            guard let relativeUrl = dic[NXSharepointOnline.KEY_RELATIVE] as! String? else {
                return false
            }
            sharepointManager?.getFolderMeataData(withSite: site, relativePath: relativeUrl)
        case .File:
            guard let relativeUrl = dic[NXSharepointOnline.KEY_RELATIVE] as! String? else {
                return false
            }
            sharepointManager?.getFileMetaData(withSite: site, filePath: relativeUrl)
        default:
            return false
        }
        getMetaDataDictionary.setValue(file, forKey: file.fullServicePath)
        return true
    }
    
    func cancelGetMetaData(file: NXFileBase) -> Bool {
        return false
    }
    
    func setDelegate(delegate: NXServiceOperationDelegate) {
        self.delegate = delegate
    }
    
    func isProgressSupported() -> Bool {
        return true
    }
    
    func setAlias(alias: String) {
        self.alias = alias
    }
    
    func getServiceAlias() -> String {
        return self.alias
    }
    
    func getUserInfo() -> Bool {
        guard isLinked == true,
            let sharepointManager = sharepointManager else {
            return false
        }
        sharepointManager.getCurrentUserInfo()
        return true
    }
    
    func cancelGetUserInfo() -> Bool {
        return false
    }
    
    //MARK: NXSharePointManagerDelegate
    func allChildItemsFinished(withSite site: String!, items: [Any]!, error: Error!) {
        let parentFolder = self.enumFolderStack.lastObject as! NXFolder
        self.enumFolderStack.removeLastObject()
        var retError: NSError? = nil
        if error != nil {
            retError = convertError2NXError(error: error as NSError?)
        }
        else {
            let newList = NSMutableArray()
            for item in items {
                let property = item as! [String: Any]
                if let nodeTypeStr = property[SP_NODE_TYPE] as! String?  {
                    let nxfolder = NXFolder()
                    if nodeTypeStr == SP_NODE_DOC_LIST {
                        fetchInfo(nxfile: nxfolder, item: property, siteurl: site, type: .Folder, parent: parentFolder)
                    }
                    else if nodeTypeStr == SP_NODE_SITE {
                        fetchInfo(nxfile: nxfolder, item: property, siteurl: site, type: .Site, parent: parentFolder)
                    }
                    nxfolder.parent = parentFolder
                    nxfolder.boundService = parentFolder.boundService
                    newList.add(nxfolder)
                }
            }
            NXCommonUtils.updateFolderChildren(folder: parentFolder, newFileList: newList)
        }
        self.delegate?.getFilesFinished?(folder: parentFolder, files: parentFolder.getChildren(), error: retError)
    }
    
    func allChildItemsInFolderFinished(withSite site: String!, folderPath: String!, items: [Any]!, error: Error!) {
        let parentFolder = self.enumFolderStack.lastObject as! NXFolder
        self.enumFolderStack.removeLastObject()
        var retError: NSError? = nil
        if error != nil {
            retError = convertError2NXError(error: error as NSError?)
        }
        else {
            let newList = NSMutableArray()
            for item in items {
                let property = item as! [String: Any]
                if let nodeTypeStr = property[SP_NODE_TYPE] as! String?  {
                    var  nxfile: NXFileBase!
                    if nodeTypeStr == SP_NODE_FOLDER {
                        nxfile = NXFolder()
                        fetchInfo(nxfile: nxfile, item: property, siteurl: site, type: .Folder, parent: parentFolder)
                    }
                    else {
                        nxfile = NXFile()
                        fetchInfo(nxfile: nxfile, item: property, siteurl: site, type: .File, parent: parentFolder)
                        nxfile.isOffline = false
                        nxfile.isFavorite = false
                    }
                    nxfile.parent = parentFolder
                    nxfile.boundService = parentFolder.boundService
                    newList.add(nxfile as Any)
                }
            }
            NXCommonUtils.updateFolderChildren(folder: parentFolder, newFileList: newList)
        }
        self.delegate?.getFilesFinished?(folder: parentFolder, files: parentFolder.getChildren(), error: retError)
    }
    
    func downloadFileFinished(withSite site: String!, filePath: String!, dstPath: String!, error: Error!) {
        var retError: NSError?
        let dic = compositeServicePath(type: .File, site: site, relatvie: filePath)
        
        if error == nil {
            if let _ = convertDictionary2Json(dic: dic) {
            }
            else {
                retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE, error: nil)
            }
        }
        else {
            retError = convertError2NXError(error: error as NSError?)
        }
        
        self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
    }
    
    func rangeDownloadFileFinished(withSite site: String!, filePath: String!, data: Data!, error: Error!) {
        var retError: NSError?
        let dic = compositeServicePath(type: .File, site: site, relatvie: filePath)
        
        if error == nil {
            if let _ = convertDictionary2Json(dic: dic) {
            }
            else {
                retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE, error: nil)
            }
        }
        else {
            retError = convertError2NXError(error: error as NSError?)
        }
        
        if retError == nil {
            do {
                try data.write(to: URL(fileURLWithPath: rangeDownloadPath!))
            } catch {
                retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_FILE_ACCESS_DENIED, error: nil)
            }
        }
        
        self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
    }
    
    func downloadProcess(withSite site: String!, filePath: String!, dstPath: String!, progress: CGFloat) {
        self.delegate?.updateProgress?(id: downloadOrUploadId!, progress: Float(progress))
    }
    
    func rangeDownloadProcess(withSite site: String!, filePath: String!, progress: CGFloat) {
        self.delegate?.updateProgress?(id: downloadOrUploadId!, progress: Float(progress))
    }
    
    func deleteFolderFinished(withSite site: String!, relativePath: String!, error: Error!) {
        var retError: NSError?
        if error != nil {
            retError = convertError2NXError(error: error as NSError?)
        }
        let dic = compositeServicePath(type: .Folder, site: site, relatvie: relativePath)
        guard let fullServicePath = convertDictionary2Json(dic: dic) else{
            return
        }
        self.delegate?.deleteFileFolderFinished?(servicePath: fullServicePath, error: retError)
    }
    
    func deleteFileFinished(withSite site: String!, filePath: String!, error: Error!) {
        var retError: NSError?
        if error != nil {
            retError = convertError2NXError(error: error as NSError?)
        }
        let dic = compositeServicePath(type: .File, site: site, relatvie: filePath)
        guard let fullServicePath = convertDictionary2Json(dic: dic) else{
            return
        }
        self.delegate?.deleteFileFolderFinished?(servicePath: fullServicePath, error: retError)
    }
    
    func createDocumentLibFinished(withSite site: String!, name: String!, item: [AnyHashable : Any]!, error: Error!) {
        let folder = NXFolder()
        var retError: NSError?
        if error != nil {
            retError = convertError2NXError(error: error as NSError?)
        }
        else if item != nil{
            fetchInfo(nxfile: folder, item: item as! [String : Any], siteurl: site, type: .Folder)
        }
        let dic = compositeServicePath(type: .Folder, site: site)
        guard let fullServicePath = convertDictionary2Json(dic: dic) else{
            return
        }
        self.delegate?.addFolderFinished?(folderName: name, parentServicePath: fullServicePath, error: retError)
    }
    
    func createFolderFinished(withSite site: String!, folderName: String!, parentPath: String!, item: [AnyHashable : Any]!, error: Error!) {
        let folder = NXFolder()
        var retError: NSError?
        if error != nil {
            retError = convertError2NXError(error: error as NSError?)
        }
        else if nil != item {
            fetchInfo(nxfile: folder, item: item as! [String : Any], siteurl: site, type: .Folder)
        }
        let dic = compositeServicePath(type: .File, site: site, relatvie: parentPath)
        guard let fullServicePath = convertDictionary2Json(dic: dic) else{
            return
        }
        self.delegate?.addFolderFinished?(folderName: folderName, parentServicePath: fullServicePath, error: retError)
    }
    
    func addFileFinished(withSite site: String!, fileName: String!, folderPath: String!, localPath: String!, error: Error!) {
        var retError: NSError?
        let dic = compositeServicePath(type: .Folder, site: site, relatvie: folderPath)
        
        if let _ = convertDictionary2Json(dic: dic) {
        }
        else {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_REST_UPLOAD_FAILED, error: nil)!
        }
        
        if error != nil {
            retError = convertError2NXError(error: error as NSError?)
        }
        
        self.delegate?.downloadOrUploadFinished?(id: downloadOrUploadId!, error: retError)
    }
    
    func addFileProcess(withSite site: String!, fileName: String!, folderPath: String!, localPath: String!, progress: CGFloat) {
        self.delegate?.updateProgress?(id: downloadOrUploadId!, progress: Float(progress))
    }
    
    func updateFileFinished(withSite site: String!, filePath: String!, localPath: String!, error: Error!) {
        var retError: NSError?
        var fullServicePath: String?
        if error != nil {
            retError = convertError2NXError(error: error as NSError?)
        }
        let dic = compositeServicePath(type: .File, site: site, relatvie: filePath)
        if let path = convertDictionary2Json(dic: dic) {
            fullServicePath = path
            let key = getUpdateTicketKey(srcPath: localPath, servicePath: path)
            updateLocalPathDictionary.removeObject(forKey: key)
            if error != nil {
                retError = convertError2NXError(error: error as NSError?)
            }
        }
        else {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_REST_UPLOAD_FAILED, error: nil)!
        }
        self.delegate?.updateFileFinished?(srcPath: localPath, fileServicePath: fullServicePath, error: retError)
    }
    
    func updateFileProcess(withSite site: String!, filePath: String!, localPath: String!, progress: CGFloat) {
        let dic = compositeServicePath(type: .File, site: site, relatvie: filePath)
        guard let fullServicePath = convertDictionary2Json(dic: dic) else{
            return
        }
        self.delegate?.updateFileProgress?(progress: Float(progress), srcPath: localPath, fileServicePath: fullServicePath)
    }
    
    func getUserInfoFinished(withEmail email: String!, url: String!, totalstorage: Int64, usedstorage: Int64, error: Error!) {
        var retError: NSError?
        if error != nil {
            retError = convertError2NXError(error: error as NSError?)
        }
        let totalNumber = NSNumber(value: totalstorage)
        let usedNumber = NSNumber(value: usedstorage)
        self.delegate?.getUserInfoFinished?(username: nil, email: email, totalQuota: totalNumber, usedQuota: usedNumber, error: retError)
    }
    
    func getSiteMetaDataFinished(withSite site: String!, item: [AnyHashable : Any]!, error: Error!) {
        var retError: NSError?
        if error != nil {
            retError = convertError2NXError(error: error as NSError?)
        }
        let dic = compositeServicePath(type: .Site, site: site)
        let fullServicePath = convertDictionary2Json(dic: dic)
        if fullServicePath != nil,
            let filebase = getMetaDataDictionary.object(forKey: fullServicePath!) as! NXFileBase? {
            getMetaDataDictionary.removeObject(forKey: fullServicePath!)
            if retError == nil && filebase is NXFolder {
                fetchInfo(nxfile: filebase, item: item as! [String : Any], siteurl: site, type: .Site)
            }
        }
        else {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE, error: nil)
        }
        self.delegate?.getMetaDataFinished?(servicePath: fullServicePath, error: retError)
    }
    
    func getFolderMetaDataFinished(withSite site: String!, relativePath: String!, item: [AnyHashable : Any]!, error: Error!) {
        var retError: NSError?
        if error != nil {
            retError = convertError2NXError(error: error as NSError?)
        }
        let dic = compositeServicePath(type: .Folder, site: site, relatvie: relativePath)
        let fullServicePath = convertDictionary2Json(dic: dic)
        if fullServicePath != nil {
            if let filebase = getMetaDataDictionary.object(forKey: fullServicePath!) as! NXFileBase? {
                getMetaDataDictionary.removeObject(forKey: fullServicePath!)
                if retError == nil && filebase is NXFolder {
                    fetchInfo(nxfile: filebase, item: item as! [String : Any], siteurl: site, type: .Folder)
                }
            }
        }
        else {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE, error: nil)
        }
        self.delegate?.getMetaDataFinished?(servicePath: fullServicePath, error: retError)
    }
    
    func getFileMetaDataFinished(withSite site: String!, filePath: String!, item: [AnyHashable : Any]!, error: Error!) {
        var retError: NSError?
        if error != nil {
            retError = convertError2NXError(error: error as NSError?)
        }
        let dic = compositeServicePath(type: .File, site: site, relatvie: filePath)
        let fullServicePath = convertDictionary2Json(dic: dic)
        if fullServicePath != nil,
            let filebase = getMetaDataDictionary.object(forKey: fullServicePath!) as! NXFileBase? {
            getMetaDataDictionary.removeObject(forKey: fullServicePath!)
            if retError == nil && filebase is NXFolder {
                fetchInfo(nxfile: filebase, item: item as! [String : Any], siteurl: site, type: .File)
            }
        }
        else {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_NOSUCHFILE, error: nil)
        }
        self.delegate?.getMetaDataFinished?(servicePath: fullServicePath, error: retError)
    }
    
    //MARK: private method
    private func convertDictionary2Json(dic: [String: Any]) -> String? {
        do {
            let jsonData = try JSONSerialization.data(withJSONObject: dic, options: .prettyPrinted)
            let str = String(data: jsonData, encoding: .utf8)
            return str
        } catch {
            Swift.print(error.localizedDescription)
        }
        return nil
    }
    
    private func convertJson2Dictionary(json: String) -> [String: Any]? {
        if let data = json.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                Swift.print(error.localizedDescription)
            }
        }
        return nil
    }
    
    private func compositeServicePath(type: SPNodeType, site: String, relatvie: String = "") -> [String: Any]{
        if type == .Site {
            return [NXSharepointOnline.KEY_TYPE: type.rawValue, NXSharepointOnline.KEY_SITE: site]
        }
        else{
            return [NXSharepointOnline.KEY_TYPE: type.rawValue, NXSharepointOnline.KEY_SITE: site, NXSharepointOnline.KEY_RELATIVE: relatvie]
        }
    }

    private func fetchInfo(nxfile: NXFileBase, item: [String: Any], siteurl: String, type: SPNodeType, parent: NXFileBase? = nil){
        if let name = item[SP_EXTERNAL_NAME_TAG] as! String? {
            nxfile.name = name
        }
        if type == .Folder ||
            type == .File {
            if let relativeurl = item[SP_EXTERNAL_RELATIVEPATH_TAG] as! String?,
                let fullSerivcePath = convertDictionary2Json(dic: compositeServicePath(type: type, site: siteurl, relatvie: relativeurl)){
                nxfile.fullServicePath = fullSerivcePath
            }
        }
        else {
            if let siteurl = item[SP_EXTERNAL_SITE_TAG] as! String?,
                let fullSerivcePath = convertDictionary2Json(dic: compositeServicePath(type: type, site: siteurl)){
                nxfile.fullServicePath = fullSerivcePath
            }
        }
        
        if let parent = parent {
            if let fullPath = NSURL(fileURLWithPath: parent.fullPath).appendingPathComponent(nxfile.name)?.path {
                nxfile.fullPath = fullPath
                if nxfile is NXFolder {
                    nxfile.fullPath.append("/")
                }
            }
        }
        
        nxfile.serviceAccountId = self.userId
        nxfile.serviceAlias = self.alias
        
        if let lastModifiedTime = item[SP_EXTERNAL_LAST_MODIFIED_DATE_TAG] as! String? {
            nxfile.lastModifiedTime  = lastModifiedTime
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ssZ"
            if let date = formatter.date(from: lastModifiedTime){
                nxfile.lastModifiedDate = date as NSDate
            }
        }
        if type == .File {
            if let sizeStr = item[SP_EXTERNAL_SIZE_TAG] as! String?,
                let size = Int64(sizeStr){
                nxfile.size = size
            }
        }
        nxfile.serviceType = NSNumber(value: ServiceType.kServiceSharepointOnline.rawValue)
        nxfile.isRoot = false
    }
    
    private func convertError2NXError(error: NSError?) -> NSError?{
        if nil == error {
            return nil
        }
        var retError = error
        if 403 == error?.code {
            if error?.userInfo["error"] as? String == "invalid_grant"{
                retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED, error: error!)
            }
        }
        else if 401 == error?.code {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED, error: error!)
        }
        else if 500 == error?.code {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_NOSUCHFILE, error: error!)
        }
        else if NSURLErrorCancelled == error?.code {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_CANCEL, error: error!)
        }
        else if error!.code < 0 {
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_TRANS_BYTES_FAILED, error: error!)
        }
        return retError
    }
    
    private func getgetUploadTicketKey(srcPath: String, servicePath: String) -> String {
        return servicePath.appending(srcPath)
    }
    
    private func getUploadTicketKey(srcPath: String, folder: NXFileBase) -> String {
        return folder.fullServicePath.appending(srcPath)
    }
    
    private func getUpdateTicketKey(srcPath: String, servicePath: String) -> String {
        return servicePath.appending(srcPath)
    }
    
    private func getUpdateTicketKey(srcPath: String, dstFile: NXFileBase) -> String {
        return dstFile.fullServicePath.appending(srcPath)
    }
}

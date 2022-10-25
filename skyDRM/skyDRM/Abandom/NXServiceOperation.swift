//
//  NXServiceOperation.swift
//  skyDRM
//
//  Created by nextlabs on 30/12/2016.
//  Copyright © 2016 nextlabs. All rights reserved.
//

import Foundation

@objc protocol NXServiceOperation : NSObjectProtocol{
    
    /// get files under the folder
    ///
    /// - Parameter folder: its type must be NXFolder
    /// - Returns: true/false
    func getFiles(folder: NXFileBase) -> Bool
    /// get files recursively under the folder
    ///
    /// - Parameter folder: its type must be NXFolder
    /// - Returns: true/false
    func getAllFilesInFolder(folder: NXFileBase) -> Bool
    /// cancel the operation of 'getFiles' or 'getAllfilesInFolder'
    ///
    /// - Parameter folder: it is the parameter in 'getFiles' or 'getAllFilesInFolder'
    /// - Returns: true/false
    func cancelGetFiles(folder: NXFileBase) -> Bool
    
    /// download the specific file, if file is existed in dstPath, it will be renamed
    ///
    /// - Parameters:
    ///   - file: specific file, its type must be NXFile
    ///   - filePath: local file path
    ///   - id: identify this request
    /// - Returns: true/false
    func downloadFile(file: NXFileBase, filePath: String, id: Int) -> Bool
    /// partial download, it starts from position zero
    /// - Parameters:
    ///   - file: its type must be NXFile
    ///   - length: the length of the file
    ///   - filePath: local file path
    ///   - id: identify this request
    /// - Returns: true/false
    func rangeDownloadFile(file: NXFileBase, length: Int, filePath: String, id: Int) -> Bool
    /// delete file
    ///
    /// - Parameter file:
    /// - Returns: true/false
    func deleteFileFolder(file: NXFileBase) -> Bool
    /// add folder
    ///
    /// - Parameters:
    ///   - folderName: new folder name
    ///   - parentFolder: parent folder
    /// - Returns: true/false
    func addFolder(folderName: String, parentFolder: NXFileBase) -> Bool
    
    /// upload file
    ///
    /// - Parameters:
    ///   - filename: new file name
    ///   - folder:  upload under which folder
    ///   - srcPath: local file path
    ///   - id: identify this request
    /// - Returns: true/false
    func uploadFile(filename: String, folder: NXFileBase, srcPath: String, fileSource: NXFileBase?, id: Int) -> Bool
    /// cancel download or upload
    ///
    /// - Parameters:
    ///   - id: identify this request
    func cancelDownloadOrUpload(id: Int)
    
    /// overwrite file
    ///
    /// - Parameters:
    ///   - srcPath: local file path
    ///   - dstFile: file to be updated
    /// - Returns: true/false
    func updateFile(srcPath: String, dstFile: NXFileBase) -> Bool
    /// cancel updating
    ///
    /// - Parameters:
    ///   - srcPath: the parameter in 'updateFile'
    ///   - dstFile: the parameter in 'updateFile'
    /// - Returns: true/false
    func cancelUpdateFile(srcPath: String, dstFile: NXFileBase) -> Bool
    
    /// get meta data of the file
    ///
    /// - Parameter file:
    /// - Returns: true/false
    func getMetaData(file: NXFileBase) -> Bool
    /// cancel getting meta data
    ///
    /// - Parameter file: it is the parameter in 'getMetaData'
    /// - Returns: true/false
    func cancelGetMetaData(file: NXFileBase) -> Bool
    
    /// set NXServiceOperationDelegate
    ///
    /// - Parameter delegate:
    /// - Returns:
    func setDelegate(delegate: NXServiceOperationDelegate)
    /// support progress of uploading and downloading or not
    ///
    /// - Returns: true/false
    func isProgressSupported() -> Bool
    
    /// set service alias
    ///
    /// - Parameter alias:
    /// - Returns:
    func setAlias(alias: String)
    /// get service alias
    ///
    /// - Returns:
    func getServiceAlias() -> String
    
    /// get userinfo, e.g. username,email,drive space etc.
    ///
    /// - Returns: true/false
    func getUserInfo() -> Bool
    /// cancel getting user info
    ///
    /// - Returns: true/false
    func cancelGetUserInfo() -> Bool
    
}

@objc protocol NXServiceOperationDelegate : NSObjectProtocol {
    
    /// called when 'getFiles' has finished
    ///
    /// - Parameters:
    ///   - servicePath: folder's service path
    ///   - files:
    ///   - error:
    @objc optional func getFilesFinished(folder: NXFileBase, files: NSArray?, error: NSError?)
    /// called when 'getAllFilesInFolder has finished
    ///
    /// - Parameters:
    ///   - servicePath: folder's service path
    ///   - files:
    ///   - error:
    @objc optional func getAllFiles(servicePath: String?, files: NSArray?, error: NSError?)
    /// called when 'deleteFile' has finished
    ///
    /// - Parameters:
    ///   - servicePath: file's service path
    ///   - error:
    @objc optional func deleteFileFolderFinished(servicePath: String?, error: NSError?)
    /// called when 'addFolder' has finished
    ///
    /// - Parameters:
    ///   - folderName: new folder name
    ///   - parentServicePath: parent service path
    ///   - error:
    @objc optional func addFolderFinished(folderName: String?, parentServicePath: String?, error: NSError?)
    /// report the progress of request
    ///
    /// - Parameters:
    ///   - id: identify this request
    ///   - progress:[0,1]
    @objc optional func updateProgress(id: Int, progress: Float)
    /// called when request has finished
    ///
    /// - Parameters:
    ///   - id: identify this request
    ///   - error:
    @objc optional func downloadOrUploadFinished(id: Int, error: NSError?)
    /// called when 'updateFile' has finished
    ///
    /// - Parameters:
    ///   - srcPath: local path
    ///   - fileServicePath: dstFile's servicePath
    ///   - error:
    @objc optional func updateFileFinished(srcPath: String?, fileServicePath: String?, error: NSError?)
    /// report the progress of 'updateFile'
    ///
    /// - Parameters:
    ///   - progress: [0,1]
    ///   - srcPath: local path
    ///   - fileServicePath: dstFile's servicePath
    @objc optional func updateFileProgress(progress: Float, srcPath: String?, fileServicePath: String?)
    /// called when 'getMetaData' has finished
    ///
    /// - Parameters:
    ///   - servicePath:file's service path
    ///   - error:
    @objc optional func getMetaDataFinished(servicePath: String?, error: NSError?)
    /// called when 'getUserInfo' has finished
    ///
    /// - Parameters:
    ///   - username: displayname
    ///   - email: email address
    ///   - totalQuota: total amount
    ///   - usedQuota: used amount
    ///   - error: 
    @objc optional func getUserInfoFinished(username: String?, email: String?, totalQuota: NSNumber?, usedQuota: NSNumber?, error: NSError?)
    
    //FIXME: use more flexiable method
    @objc optional func getUserInfoFinishedExtraData(username: String?, email: String?, totalQuota: NSNumber?, usedQuota: NSNumber?, property: Any?, error: NSError?)
}


/**
 *
 * for dropbox drive methods.
 *
 **/


import Foundation
import SwiftyDropbox

class NXDropbox: NSObject, NXServiceOperation{
    var fileHandler: SwiftyDropbox.FilesRoutes!
    var userHandler: SwiftyDropbox.UsersRoutes!
    
    weak var serviceDelegate: NXServiceOperationDelegate?
    
    var updateRequest:UploadRequest<Files.FileMetadataSerializer, Files.UploadErrorSerializer>? = nil
    var getMetaInfoRequest:RpcRequest<Files.MetadataSerializer, Files.GetMetadataErrorSerializer>? = nil
    
    
    var uid = ""
    var alias = ""
    var accessToken = ""
 
    var downloadRequest:DownloadRequestFile<Files.FileMetadataSerializer, Files.DownloadErrorSerializer>? = nil
    var uploadRequest:UploadRequest<Files.FileMetadataSerializer, Files.UploadErrorSerializer>? = nil
    var listRequest: RpcRequest<Files.ListFolderResultSerializer, Files.ListFolderErrorSerializer>? = nil
    
    private var downloadOrUploadId : Int? = nil
    
    init(userId: String, alias: String, accessToken: String) {
        super.init()
        self.uid = userId
        self.alias = alias
        self.accessToken = accessToken
        userHandler = DropboxClient(accessToken: accessToken).users
        fileHandler = DropboxClient(accessToken: accessToken).files
    }
    
    //MARK: NXServiceOperation
    func getFiles(folder: NXFileBase) -> Bool{
        guard folder is NXFolder else {
            return false
        }
        if folder.isRoot {
            folder.fullPath = "/"
            folder.fullServicePath = ""
        }
        listRequest = fileHandler.listFolder(path: folder.fullServicePath).response{ response, error in
            if response != nil {
                let newList = NSMutableArray()
                for item in (response?.entries)! {
                    var nxfile : NXFileBase!
                    switch item {
                    case _ as Files.FileMetadata:
                        nxfile = NXFile()
                    case _ as Files.FolderMetadata:
                        nxfile = NXFolder()
                    case let deleted as Files.DeletedMetadata:
                        Swift.print("deleted: \(deleted.name)")
                    default: fatalError("Tried to serialize unexpected subtype")
                    }
                    
                    self.formatNXFile(nxfile: nxfile, item: item, parent: folder)
                    nxfile.parent = folder
                    newList.add(nxfile)
                }
                NXCommonUtils.updateFolderChildren(folder: folder, newFileList: newList)
                self.serviceDelegate?.getFilesFinished?(folder: folder, files: newList as NSArray?, error: nil)
            }else if let error = error{
                let retError = self.convertError2NXError(error: error)
                self.serviceDelegate?.getFilesFinished?(folder: folder, files: nil, error: retError)
            }
        }
        return true
    }
    
    func getAllFilesInFolder(folder: NXFileBase) -> Bool{
        //recursive fetch all files. useless here.
        return false
    }
    
    func cancelGetFiles(folder: NXFileBase) -> Bool{
        listRequest?.cancel()
        return true
    }
    
    func downloadFile(file: NXFileBase, filePath: String, id: Int) -> Bool {
        guard file is NXFile else {
            return false
        }
        
        let destURL = URL(fileURLWithPath: filePath)
        let destination: (URL, HTTPURLResponse) -> URL = { temporaryURL, response in
            return destURL
        }
        
        downloadRequest = fileHandler.download(path: file.fullServicePath, overwrite: true, destination: destination).response { response, error in
            if response != nil {
                self.serviceDelegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: nil)
            }
            else if let error = error {
                let retError = self.convertError2NXError(error: error)
                self.serviceDelegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: retError)
            }
        }.progress { progressData in
            self.serviceDelegate?.updateProgress?(id: self.downloadOrUploadId!, progress: Float(progressData.fractionCompleted))
        }
        
        downloadOrUploadId = id
        
        return true
    }
    
    func rangeDownloadFile(file: NXFileBase, length: Int, filePath: String, id: Int) -> Bool {
        guard file is NXFile else {
            return false
        }
        
        let destURL = URL(fileURLWithPath: filePath)
        let destination: (URL, HTTPURLResponse) -> URL = { temporaryURL, response in
            return destURL
        }
        
        let range = NSMakeRange(0, length)
        downloadRequest = fileHandler.download(path: file.fullServicePath, range: range, overwrite: true, destination: destination).response { response, error in
            if response != nil {
                guard let content = try? Data(contentsOf: destURL),
                    content.count >= length else {
                        let retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_RENDER_FILE_FAILED.rawValue, userInfo: nil)
                        self.serviceDelegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: retError)
                        return
                }
                self.serviceDelegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: nil)
            }
            else if let error = error {
                let retError = self.convertError2NXError(error: error)
                self.serviceDelegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: retError)
            }
        }.progress { progressData in
            self.serviceDelegate?.updateProgress?(id: self.downloadOrUploadId!, progress: Float(progressData.fractionCompleted))
        }
    
        downloadOrUploadId = id
    
        return true
    }
    
    func deleteFileFolder(file: NXFileBase) -> Bool{
        fileHandler.delete(path: file.fullServicePath).response { response, error in
            var retError: NSError?
            if let error = error {
                retError = self.convertError2NXError(error: error)
            }
            self.serviceDelegate?.deleteFileFolderFinished?(servicePath: file.fullServicePath, error: retError)
        }
        return true
    }
    
    func addFolder(folderName: String, parentFolder: NXFileBase) -> Bool{
        guard parentFolder is NXFolder else {
            return false
        }
        let folderPath = "\(parentFolder.fullServicePath)/\(folderName)"
        fileHandler.createFolder(path: folderPath).response { response, error in
            var retError: NSError?
            if let error = error {
                retError = self.convertError2NXError(error: error)
            }
            self.serviceDelegate?.addFolderFinished?(folderName: folderName, parentServicePath: parentFolder.fullServicePath, error: retError)
        }
        return true
    }
    
    func uploadFile(filename: String, folder: NXFileBase, srcPath: String, fileSource: NXFileBase? = nil, id: Int) -> Bool {
        guard folder is NXFolder else{
            return false
        }
        
        let srcUrl = URL(fileURLWithPath: srcPath)
        let mode: Files.WriteMode = .add
        let destPath = folder.isRoot ? "/\(filename)" : "\(folder.fullServicePath)/\(filename)"
        
        uploadRequest = fileHandler.upload(path: destPath, mode: mode, input: srcUrl).response { response, error in
            var retError: NSError?
            if let error = error {
                retError = self.convertError2NXError(error: error)
            }
        
            self.serviceDelegate?.downloadOrUploadFinished?(id: self.downloadOrUploadId!, error: retError)
        }.progress { progressData in
            self.serviceDelegate!.updateProgress?(id: self.downloadOrUploadId!, progress: Float(progressData.fractionCompleted))
        }
        
        downloadOrUploadId = id
        
        return true
    }
    
    func cancelDownloadOrUpload(id: Int) {
        guard downloadOrUploadId == id else {
            return
        }
        
        downloadRequest?.cancel()
        uploadRequest?.cancel()
    }
    
    func updateFile(srcPath: String, dstFile: NXFileBase) -> Bool {
        guard dstFile is NXFile else{
            return false
        }
        
        var destPath = ""
        let srcUrl = URL(fileURLWithPath: srcPath)
        let mode: Files.WriteMode = .overwrite
        destPath = dstFile.fullServicePath
        updateRequest = fileHandler.upload(path: destPath, mode: mode, input: srcUrl).response { response, error in
            var retError: NSError?
            if let error = error {
                retError = self.convertError2NXError(error: error)
            }
            self.serviceDelegate?.updateFileFinished?(srcPath: srcPath, fileServicePath: dstFile.fullServicePath, error: retError)
            self.updateRequest = nil
            }.progress { progressData in
                self.serviceDelegate?.updateFileProgress?(progress: Float(progressData.fractionCompleted), srcPath: srcPath, fileServicePath: dstFile.fullServicePath)
        }
        return true
    }
    
    func cancelUpdateFile(srcPath: String, dstFile: NXFileBase) -> Bool {
        guard let updateRequest = updateRequest else {
            return false
        }
        updateRequest.cancel()
        return false
    }
    
    func getMetaData(file: NXFileBase) -> Bool{
        if file.isRoot {
            return false
        }
        getMetaInfoRequest = fileHandler.getMetadata(path: file.fullServicePath).response { response, error in
            var retError: NSError?
            if let error = error {
                retError = self.convertError2NXError(error: error)
            }
            self.serviceDelegate?.getMetaDataFinished?(servicePath: file.fullServicePath, error: retError)
            self.getMetaInfoRequest = nil
        }
        return true

    }
    
    func cancelGetMetaData(file: NXFileBase) -> Bool{
        guard getMetaInfoRequest != nil else{
            return false
        }
        getMetaInfoRequest?.cancel()
        return true
    }
    
    func setDelegate(delegate : NXServiceOperationDelegate){
        self.serviceDelegate = delegate
    }
    
    func isProgressSupported() -> Bool{
        return true
    }
    
    func setAlias(alias : String){
        self.alias = alias
    }
    
    func getServiceAlias() -> String{
        return self.alias
    }
    
    func getUserInfo() -> Bool{
        userHandler.getCurrentAccount().response { response, error in
            var retError: NSError?
            if let error = error {
                retError = self.convertError2NXError(error: error)
            }
            self.serviceDelegate?.getUserInfoFinished?(username: response?.name.displayName, email: response?.email, totalQuota: 0, usedQuota: 0, error: retError)
        }
        return true
    }
    
    func cancelGetUserInfo() -> Bool{
        return false
    }
    
    private func formatNXFile(nxfile: NXFileBase, item: Files.Metadata, parent: NXFileBase){
        nxfile.name = item.name
        nxfile.isOffline = false
        nxfile.isFavorite = false
        if let fullPath = NSURL(fileURLWithPath: parent.fullPath).appendingPathComponent(item.name)?.path {
            nxfile.fullPath = fullPath
            if nxfile is NXFolder {
                nxfile.fullPath.append("/")
            }
        }
        if let fullServicePath = item.pathLower {
            nxfile.fullServicePath = fullServicePath
        }
        nxfile.serviceAccountId = self.uid
        nxfile.serviceAlias = self.alias
        switch item{
        case let temp as Files.FileMetadata:
            nxfile.lastModifiedDate = temp.serverModified as NSDate
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            let timeString = formatter.string(from: temp.serverModified)
            nxfile.lastModifiedTime = timeString
            nxfile.size = Int64(temp.size)
        case _ as Files.FolderMetadata:
            nxfile.lastModifiedDate = NSDate()
            nxfile.lastModifiedTime = ""
            nxfile.size = 0
        default:
            Swift.print("default")
        }
        nxfile.serviceType = NSNumber(value: ServiceType.kServiceDropbox.rawValue)
        nxfile.boundService = parent.boundService
    }
    
    private func convertError2NXError<EType>(error: CallError<EType>) -> NSError? {
        var retError: NSError?
        switch error {
        case .authError(let authError, _):
            switch authError {
            case .invalidAccessToken:
                retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_SERVICE_ACCESS_UNAUTHORIZED, error: nil)
            default:
                retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_AUTHFAILED, error: nil)
            }
        case .clientError(let clientError):
            if (clientError as? NSError)?.code == -999 {
                retError = NSError(domain: NX_ERROR_SERVICEDOMAIN, code: NXRMC_ERROR_CODE.NXRMC_ERROR_CODE_CANCEL.rawValue, userInfo: nil)
            } else {
                retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_TRANS_BYTES_FAILED, error: clientError as? NSError)
            }
        
        case .routeError(let boxed, _):
            if let listFolderError = boxed.unboxed as? Files.ListFolderError {
                switch listFolderError {
                case .path(let lookupError):
                    switch lookupError {
                    case .notFile, .notFound, .notFolder:
                        retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_NOSUCHFILE, error: nil)
                    default:
                        retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_TRANS_BYTES_FAILED, error: nil)
                    }
                default:
                    retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_TRANS_BYTES_FAILED, error: nil)
                }
            }
            else if let downloadError = boxed.unboxed as? Files.DownloadError {
                switch downloadError {
                case .path(let lookupError):
                    switch lookupError {
                    case .notFile, .notFound, .notFolder:
                        retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_NOSUCHFILE, error: nil)
                    default:
                        retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_TRANS_BYTES_FAILED, error: nil)
                    }
                default:
                    retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_TRANS_BYTES_FAILED, error: nil)
                }
                
            }
            else if let uploadError = boxed.unboxed as? Files.UploadError {
                switch uploadError {
                case .path(let path):
                    switch path.reason  {
                    case .insufficientSpace:
                            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_DRIVE_STORAGE_EXCEEDED, error: nil)
                        default:
                            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_REST_UPLOAD_FAILED, error: nil)
                    }
                default:
                    retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_TRANS_BYTES_FAILED, error: nil)
                }
            }
            else if let addFolderError = boxed.unboxed as? Files.CreateFolderError {
                switch addFolderError {
                case .path(_):
                    retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_NOSUCHFILE, error: nil)
                }
            }
            else if let getMetaError = boxed.unboxed as? Files.GetMetadataError {
                switch getMetaError {
                case .path(let lookupError):
                    switch lookupError {
                    case .notFile, .notFound, .notFolder:
                        retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_NOSUCHFILE, error: nil)
                    default:
                        retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_TRANS_BYTES_FAILED, error: nil)
                    }
                }
            }
            else {
                retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_TRANS_BYTES_FAILED, error: nil)
            }
        default:
            retError = NXCommonUtils.getNXErrorFromErrorCode(errorCode: .NXRMC_ERROR_CODE_TRANS_BYTES_FAILED, error: nil)
        }
        
        return retError
    }
}

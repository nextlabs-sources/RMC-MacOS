//
//  NXFileRenderProxy.swift
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 4/14/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Cocoa
import SDML

/// Get origin file after parse.
class NXFileRenderProxy: NSObject {
    
    var nxFileItem = NXFileRenderItem()
    
    weak var delegate: NXFileRenderDelegate?
    
    var id: String?
    
    func parseFile(file: NXFileBase, type: NXCommonUtils.renderEventSrcType) {
        
        nxFileItem.fileItem = file
        nxFileItem.srcType = type
        
        // Not nxl file.
        guard let _ = file as? NXNXLFile else {
            self.nxFileItem.autoDelete = false
            self.delegate?.parseFileFinish(path: file.localPath, error: nil)
            return
        }
        
        parseNXLFile()
    }
    
    func cancel() {
        if let id = id {
            _ = NXClient.getCurrentClient().cancelDownload(id: id)
            self.id = nil
        }
    }
}

// MARK: Private methods.

extension NXFileRenderProxy {
    
    private func parseNXLFile() {
        getRight { (error) in
            if let error = error {
                self.handleError(error: error)
                return
            }
            
            self.checkViewRight { (isAllow, error) in
                if let error = error {
                    self.handleError(error: error)
                    return
                }
                
                if isAllow == false {
                    self.addViewLog(isAllow: false)
                    NSAlert.showAlert(withMessage: "FILE_RENDER_NOT_AUTH".localized) { type in
                        self.delegate?.parseFileFinish(path: "", error: NSError())
                    }
                    return
                }
                
                if self.isRemoteView() {
                    let pathID = self.nxFileItem.fileItem?.fullServicePath
                    self.delegate?.parseFileFinish(path: pathID ?? "", error: nil)
                    return
                }
                
                self.id = self.downloadFile { (error) in
                    self.id = nil
                    if let error = error {
                        self.handleError(error: error)
                        return
                    }
                    
                    self.decryptFile { destPath, error in
                        if let error = error {
                            self.handleError(error: error)
                            return
                        }
                        
                        self.addViewLog(isAllow: true)
                        
                        self.nxFileItem.tempFilePath = destPath
                        self.delegate?.parseFileFinish(path: destPath ?? "", error: nil)
                        
                    }
                }
            }
        }
    }
    
    private func getRight(completion: @escaping (Error?) -> ()) {
        let nxlFile = nxFileItem.fileItem as! NXNXLFile
        
        if let right = nxlFile.rights {
            nxFileItem.isSteward = nxlFile.isOwner
            let rightOb = NXRightObligation()
            rightOb.rights = right
            rightOb.watermark = nxlFile.watermark
            rightOb.expiry = nxlFile.expiry
            nxFileItem.rightOb = rightOb
            
            nxFileItem.isTag = nxlFile.isTagFile
            nxFileItem.tags = nxlFile.tags
            
            completion(nil)
            return
            
        } else if nxlFile.localPath != "" {
            NXClient.getCurrentClient().getRight(path: nxlFile.localPath) { (value, error) in
                guard let value = value else {
                    completion(error)
                    return
                }
                /////////
                self.nxFileItem.isSteward = value.isOwner
                self.nxFileItem.rightOb = value.rights
                if value.tags != nil{
                    self.nxFileItem.isTag = true
                    self.nxFileItem.tags = value.tags
                } else {
                    self.nxFileItem.isTag = false
                    self.nxFileItem.tags = nil
                }
                
                completion(nil)
                return
                
            }
        } else {
            let sdmlNxlFile = nxlFile.sdmlBaseFile as! SDMLNXLFile
            sdmlNxlFile.getOnlineRightObligation { (result) in
                guard let sdmlObligation = result.value else {
                    completion(result.error)
                    return
                }
                
                
                self.nxFileItem.isSteward = sdmlNxlFile.getIsOwner()
                let obligation = NXRightObligation()
                NXCommonUtils.transform(from: sdmlObligation!, to: obligation)
                self.nxFileItem.rightOb = obligation
                
                self.nxFileItem.isTag = sdmlNxlFile.isTagFile()
                self.nxFileItem.tags = sdmlNxlFile.getTag()
                
                completion(nil)
                return
            }
        }
        
    }
    
    private func checkViewRight(completion: @escaping (Bool?, Error?) -> ()) {
        let isOwner = self.nxFileItem.isSteward!
        let isTag = self.nxFileItem.isTag!
        let right = self.nxFileItem.rightOb!
        NXClient.checkViewRight(isOwner: isOwner, isTag: isTag, right: right, completion: completion)
    }
    
    private func isRemoteView() -> Bool {
        let file = self.nxFileItem.fileItem!
        if NXFileRenderSupportUtil.renderFileType(fileName: file.name) == NXFileContentType.REMOTEVIEW {
            if (file is NXMyVaultFile && !(file is NXShareWithMeFile)) || file is NXProjectFileModel {
                return true
            }
        }
        
        return false
    }
    
    private func downloadFile(completion: @escaping (Error?) -> ()) -> String {
        let file = self.nxFileItem.fileItem!
        if file.sdmlBaseFile?.isFullFileDownloaded() == true {
            completion(nil)
            return ""
        }
          
        return NXClient.getCurrentClient().viewFileOnline(file: file) { [weak self] (file, error) in
            guard let newFile = file  else {
                completion(error)
                return
            }
            
            self?.nxFileItem.fileItem = newFile
            completion(nil)
            return
        }
    }
    
    private func decryptFile(completion: @escaping (String?, Error?) -> ()) {
        let nxlFile = self.nxFileItem.fileItem as! NXNXLFile
        
        decrypt(file: nxlFile, completion: completion)
    }
    
    private func decrypt(file: NXNXLFile, completion: @escaping (String?, Error?) -> ()) {
        if self.nxFileItem.srcType == NXCommonUtils.renderEventSrcType.cache {
            let tempFolder = NXCommonUtils.getTempFolder()!.path
            NXClient.getCurrentClient().decryptFile(file: file, toFolder: tempFolder, isOverwrite: true) { (destPath, error) in
                completion(destPath, error)
                return
            }
        } else {
            let tempFolder = NXCommonUtils.getTempFolder()!.path
            NXClient.getCurrentClient().decryptFile(path: file.localPath, toFolder: tempFolder, isOverwrite: true) { (destPath, error) in
                completion(destPath, error)
                return
            }
        }
    }
    
    private func handleError(error: Error) {
        
        if let sdmlError = error as? SDMLError,
            case SDMLError.commonFailed(reason: SDMLError.CommonFailedReason.networkUnreachable) = sdmlError {
            NSAlert.showAlert(withMessage: "ERROR_LOSE_CONNECT".localized) { type in
                self.delegate?.parseFileFinish(path: "", error: error as NSError)
            }
        } else {
            self.addViewLog(isAllow: false)
            NSAlert.showAlert(withMessage: "FILE_RENDER_NOT_AUTH".localized) { type in
                self.delegate?.parseFileFinish(path: "", error: error as NSError)
            }
        }
    }
    
    private func addViewLog(isAllow: Bool) {
        NXCommonUtils.addLog(file: nxFileItem.fileItem!, operation: "View", isAllow: isAllow)
    }
}

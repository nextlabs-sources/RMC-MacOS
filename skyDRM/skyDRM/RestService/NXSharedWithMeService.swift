//
//  NXSharedWithMeService.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 14/06/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

/// generate uuid and return it back in future
protocol NXSharedWithMeServiceOperation {
    func listFile(with filter: NXSharedWithMeListFilter?)
    func downloadFile(file: NXFileBase, to: String, id: Int, forViewer: Bool) -> Bool
    func cancelDownloadFile(id: Int)
    
    func reshareFile(file: NXFileBase, shareWith: String)
}

protocol NXSharedWithMeServiceDelegate: NSObjectProtocol {
    func listFileFinish(with filter: NXSharedWithMeListFilter?, files: [NXFileBase]?, error: Error?)
    func downloadFileFinish(id: Int, error: Error?)
    func downloadProgress(id: Int, progress: Float)
    
    func reshareFinish(newTransactionId: String?, sharedLink: String?, alreadySharedList: [String]?, newSharedList: [String]?, error: Error?)
}

extension NXSharedWithMeServiceDelegate {
    func listFileFinish(with filter: NXSharedWithMeListFilter?, files: [NXFileBase]?, error: Error?) {}
    func downloadFileFinish(id: Int, error: Error?) {}
    func downloadProgress(id: Int, progress: Float) {}
    
    func reshareFinish(newTransactionId: String?, sharedLink: String?, alreadySharedList: [String]?, newSharedList: [String]?, error: Error?) {}
}

extension NXSharedWithMeService: NXSharedWithMeServiceOperation {
    
    func listFile(with filter: NXSharedWithMeListFilter? = nil) {
        
        let (id, restProvider) = createRestProvider()
        
        let completion: NXSharedWithMeRestProviderOperation.listFileCompletion = {
            items, error in
            
            self.unfinishRequest.removeValue(forKey: id)
            
            if let items = items {
                let files = items.map() {
                    item -> NXFileBase in
                    let file = NXSharedWithMeFile()
                    self.fetchFileInfo(from: item, to: file)
                    return file
                }
                self.delegate?.listFileFinish(with: filter, files: files, error: nil)
            } else {
                self.delegate?.listFileFinish(with: filter, files: nil, error: error)
            }
            
        }
        
        restProvider.listFile(filter: filter, completion: completion)
    }
    
    func downloadFile(file: NXFileBase, to: String, id: Int, forViewer: Bool) -> Bool {
        
        guard let file = file as? NXSharedWithMeFile else {
            return false
        }
        
        let (idStr, restProvider) = createRestProvider(with: String(id))
        
        let progressHandler: (Double) -> Void = {
            progess in
            self.delegate?.downloadProgress(id: id, progress: Float(progess))
        }
        
        let completion: NXSharedWithMeRestProviderOperation.downloadFileCompletion = {
            _, error in
            
            self.unfinishRequest.removeValue(forKey: idStr)
            
            self.delegate?.downloadFileFinish(id: id, error: error)
        }
        
        let item = NXSharedWithMeFileItem()
        fetchFileInfo(from: file, to: item)
        
        restProvider.downloadFile(item: item, to: to, forViewer: forViewer, progressHandler: progressHandler, completion: completion)
        
        return true
    }
    
    func cancelDownloadFile(id: Int) {
        let restProvider = unfinishRequest.removeValue(forKey: String(id))
        restProvider?.cancel()
    }
    
    func reshareFile(file: NXFileBase, shareWith: String) {
        guard let file = file as? NXSharedWithMeFile else {
            return
        }
        
        let (id, restProvider) = createRestProvider()
        
        let completion: NXSharedWithMeRestProviderOperation.reshareFileCompletion = {
            newTransactionId, sharedLink, alreadySharedList, newSharedList, error in
            
            self.unfinishRequest.removeValue(forKey: id)
            
            self.delegate?.reshareFinish(newTransactionId: newTransactionId, sharedLink: sharedLink, alreadySharedList: alreadySharedList, newSharedList: newSharedList, error: error)
        }
        
        let item = NXSharedWithMeFileItem()
        fetchFileInfo(from: file, to: item)
        
        restProvider.reshareFile(item: item, shareWith: shareWith, completion: completion)
    }
}

class NXSharedWithMeService {
    weak var delegate: NXSharedWithMeServiceDelegate?
    
    var unfinishRequest = [String: NXSharedWithMeRestProvider]()
}

extension NXSharedWithMeService {
    
    fileprivate func createRestProvider(with id: String? = nil) -> (String, NXSharedWithMeRestProvider) {
        let restProvider = NXSharedWithMeRestProvider()
        
        // store
        let id = id ?? UUID().uuidString
        unfinishRequest[id] = restProvider
        
        return (id, restProvider)
    }
    
    fileprivate func fetchFileInfo(from item: NXSharedWithMeFileItem, to file: NXSharedWithMeFile) {
        file.setNXLID(nxlId: item.duid)
        file.name = item.name ?? ""
        file.size = Int64.init(item.size ?? 0)
        
        if let sharedDate = item.sharedDate {
            let date = NSDate(timeIntervalSince1970: (Double(sharedDate)/1000))
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd HH:mm:ss"
            file.sharedDate = formatter.string(from: date as Date)
            file.lastModifiedDate = date
            file.lastModifiedTime = formatter.string(from: date as Date)
        }
        file.sharedBy = item.sharedBy
        file.transactionId = item.transactionId
        file.transactionCode = item.transactionCode
        file.sharedLink = item.sharedLink
        file.comment = item.comment
        file.setIsOwner(isOwner: item.isOwner)
    }
    
    fileprivate func fetchFileInfo(from file: NXSharedWithMeFile, to item: NXSharedWithMeFileItem) {
        item.transactionId = file.transactionId
        item.transactionCode = file.transactionCode
    }
}

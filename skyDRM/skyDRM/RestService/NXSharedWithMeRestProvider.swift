//
//  NXSharedWithMeRestProvider.swift
//  skyDRM
//
//  Created by Paul (Qian) Chen on 14/06/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

protocol NXSharedWithMeRestProviderOperation {
    func listFile(filter: NXSharedWithMeListFilter?, completion: @escaping listFileCompletion)
    func downloadFile(item: NXSharedWithMeFileItem, to: String, forViewer: Bool, progressHandler: @escaping progressCompletion, completion: @escaping downloadFileCompletion)
    func reshareFile(item: NXSharedWithMeFileItem, shareWith: String, completion: @escaping reshareFileCompletion)
    
    func cancel()
    
    
    typealias progressCompletion = (Double) -> Void
    
    typealias listFileCompletion = ([NXSharedWithMeFileItem]?, Error?) -> Void
    typealias reshareFileCompletion = (String?, String?, [String]?, [String]?, Error?) -> Void
    typealias downloadFileCompletion = (String?, Error?) -> Void
    
}

extension NXSharedWithMeRestProvider: NXSharedWithMeRestProviderOperation {
    
    func listFile(filter: NXSharedWithMeListFilter?, completion: @escaping NXSharedWithMeRestProviderOperation.listFileCompletion) {
        let parameter: [String: Any]? = {
            if let filter = filter {
                return [RequestParameter.filter: filter]
            }
            
            return nil
        }()
        
        
        let restCompletion: (Any?, Error?) -> Void = {
            response, error in
            let items: [NXSharedWithMeFileItem]? = {
                if let response = response as? NXSharedWithMeResponse.ListFileResponse {
                   return response.items
                }
                
                return nil
            }()
            
            completion(items, error)
        }
        
        api = NXSharedWithMeAPI(with: .listFile)
        api?.sendRequest(withParameters: parameter, completion: restCompletion)
    }
    
    func downloadFile(item: NXSharedWithMeFileItem, to: String, forViewer: Bool, progressHandler: @escaping NXSharedWithMeRestProviderOperation.progressCompletion, completion: @escaping NXSharedWithMeRestProviderOperation.downloadFileCompletion) {
        
        guard
            let transactionId = item.transactionId,
            let transactionCode = item.transactionCode
            else { return } // call finish delegate with error
        
        let parameter = [RequestParameter.body: [Constant.kTransactionId: transactionId,
                                                 Constant.kTransactionCode: transactionCode,
                                                 Constant.kForViewer: forViewer]]
        let restCompletion: (Any?, Error?) -> Void = {
            response, error in
            
            let filename: String? = {
                if let response = response as? NXSharedWithMeResponse.DownloadFileResponse {
                    return response.filename
                }
                
                return nil
            }()
            
            completion(filename, error)
        }
        
        api = NXSharedWithMeAPI(with: .downloadFile)
        api?.downloadFile(withParameters: parameter, destination: to, progress: progressHandler, completion: restCompletion)
    }
    
    func cancel() {
        _ = api?.cancel()
    }
    
    func reshareFile(item: NXSharedWithMeFileItem, shareWith: String, completion: @escaping NXSharedWithMeRestProviderOperation.reshareFileCompletion) {
        
        guard
            let transactionId = item.transactionId,
            let transactionCode = item.transactionCode
            else { return } // call finish delegate with error
        
        let parameter = [RequestParameter.body: [Constant.kTransactionId: transactionId,
                                                 Constant.kTransactionCode: transactionCode,
                                                 Constant.kShareWith: shareWith]]
        let restCompletion: (Any?, Error?) -> Void = {
            response, error in
            
            if error == nil {
                guard let response = response as? NXSharedWithMeResponse.ResharedFileResponse else {
                    // not run
                    debugPrint("not run")
                    return
                }
                
                completion(response.newTransactionId, response.sharedLink, response.alreadySharedList, response.newSharedList, nil)
            } else {
                completion(nil, nil, nil, nil, error)
            }
        }
        
        api = NXSharedWithMeAPI(with: .reshareFile)
        api?.sendRequest(withParameters: parameter, completion: restCompletion)
    }
}

// 1 provider to 1 api
class NXSharedWithMeRestProvider {
    fileprivate struct Constant {
        static let kTransactionId = "transactionId"
        static let kTransactionCode = "transactionCode"
        static let kShareWith = "shareWith"
        static let kForViewer = "forViewer"
    }
    
    var api: RestAPI?
}

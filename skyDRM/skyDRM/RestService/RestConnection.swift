//
//  RestConnection.swift
//  skyDRM
//
//  Created by pchen on 04/02/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation
import Alamofire

protocol NetworkOperation {
    func sendRequest(_ request: URLRequest, progressHandler: ((Double) -> Void)?, responseHandler: @escaping ResponseHandler)
    func download(request: URLRequest, destination: String, progressHandler: ((Double) -> Void)?, responseHandler: @escaping ResponseHandler, fileNameHandler: ((String?) -> Void)?)
    func upload(request: URLRequest, parameters: [UploadPartFormData], progressHandler: ((Double) -> Void)?, responseHandler: @escaping ResponseHandler)
    func cancel() -> Bool
}

class RestConnection: NetworkOperation {
    
    open func sendRequest(_ request: URLRequest, progressHandler: ((Double) -> Void)? = nil, responseHandler: @escaping ResponseHandler) {
        let dataRequest = Alamofire.request(request)
        dataRequest.response {
            response in
            responseHandler(response.response, response.data, response.error)
        }
        dataRequest.downloadProgress {
            progressBar in
            progressHandler?(progressBar.fractionCompleted)
        }
        
        manager = dataRequest
    }
    
    open func download(request: URLRequest, destination: String, progressHandler: ((Double) -> Void)?, responseHandler: @escaping ResponseHandler, fileNameHandler: ((String?) -> Void)? = nil) {
        
        let destinationURL: DownloadRequest.DownloadFileDestination = { _, response in
            
            var fileURL = URL(fileURLWithPath: destination)
            
            if response.allHeaderFields[ResponseHeader.kContentDisposition] != nil,
                let fileName = response.suggestedFilename {
                fileURL.deleteLastPathComponent()
                fileURL.appendPathComponent(fileName)
            }
            
            return (fileURL, [.removePreviousFile, .createIntermediateDirectories])
        }
        
        let downloadRequest = Alamofire.download(request, to: destinationURL)
        downloadRequest.responseData() {
            response in
            switch response.result {
            case .success(let object):
                responseHandler(response.response, object, nil)
            case .failure(let error):
                responseHandler(response.response, nil, error)
            }
        }
        
        var isFirst = true
        downloadRequest.downloadProgress() {
            progressBar in
            
            if isFirst {
                var fileName: String? = nil
                if downloadRequest.response?.allHeaderFields[ResponseHeader.kContentDisposition] != nil {
                    fileName = downloadRequest.response?.suggestedFilename
                }
                
                fileNameHandler?(fileName)
                
                isFirst = false
            }
            progressHandler?(progressBar.fractionCompleted)
        }
        
        manager = downloadRequest
    }
    
    open func upload(request: URLRequest, parameters: [UploadPartFormData], progressHandler: ((Double) -> Void)?, responseHandler: @escaping ResponseHandler) {
        Alamofire.upload(multipartFormData: {
            multipartFormData in
            for object in parameters {
                if let fileName = object.fileName, let mimeType = object.mimeType {
                    multipartFormData.append(object.data, withName: object.name, fileName: fileName, mimeType: mimeType)
                } else {
                    multipartFormData.append(object.data, withName: object.name)
                }
            }
        }, with: request) {
            result in
            switch result {
            case .success(let upload, _, _):
                upload.responseJSON() {
                    response in
                    switch response.result {
                    case .success(let object):
                        responseHandler(response.response, object, nil)
                    case .failure(let error):
                        responseHandler(response.response, nil, error)
                    }
                }
                upload.uploadProgress() {
                    progressBar in
                    progressHandler?(progressBar.fractionCompleted)
                }
                
                self.manager = upload
                
            case .failure(let error):
                responseHandler(nil, nil, error)
            }
        }
    }
    
    open func cancel() -> Bool {
        
        guard let manager = manager else {
            return false
        }
        
        manager.cancel()
        
        return true
    }
    
    var manager: Alamofire.Request?
}

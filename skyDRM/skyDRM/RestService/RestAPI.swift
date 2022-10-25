//
//  RestAPI.swift
//  skyDRM
//
//  Created by pchen on 11/01/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

//TODO : Error handling
enum BackendError: Error {
    case badRequest(reason: String)
    case failResponse(reason: String)
    case notFound // 404
    case notModified // 304
    
}

struct UploadPartFormData {
    var name: String
    var data: Data
    var fileName: String?
    var mimeType: String?
}

typealias CallBack = ((Any?, Error?) -> Void)

protocol RestAPIOperation {
    
    func sendRequest(withParameters parameters: Any?,
                     progress: ((Double) -> Void)?,
                     completion: @escaping CallBack)
    
    func downloadFile(withParameters parameters: Any?,
                      destination: String,
                      progress: ((Double) -> Void)?,
                      completion: @escaping CallBack,
                      fileNameHandler: ((String?) -> Void)?)
    
    func uploadFile(withParameters parameters: Any?,
                    progress: ((Double) -> Void)?,
                    completion: @escaping CallBack)
    func cancel() -> Bool
}

extension RestAPI: RestAPIOperation {
    
    func sendRequest(withParameters parameters: Any?, progress: ((Double) -> Void)? = nil, completion: @escaping CallBack) {
        do {
            var request = try generateRequest(withParameters: parameters)
            if !(self is NXCheckUpgradeAPI) {
                handleRequest(request: &request)
            }
            guard let responseHandler = analysisResponse(withCompletion: completion) else { return }
            connection.sendRequest(request, progressHandler: progress, responseHandler: responseHandler)
        } catch {
            completion(nil, error)
            return
        }
    }
    
    func downloadFile(withParameters parameters: Any?, destination: String, progress: ((Double) -> Void)?, completion: @escaping CallBack, fileNameHandler: ((String?) -> Void)? = nil) {
        do {
            var request = try generateRequest(withParameters: parameters)
            handleRequest(request: &request)
            guard let responseHandler = analysisResponse(withCompletion: completion) else { return }
            connection.download(request: request, destination: destination, progressHandler: progress, responseHandler: responseHandler, fileNameHandler: fileNameHandler)
        } catch {
            completion(nil, error)
            return
        }
    }
    
    func uploadFile(withParameters parameters: Any?, progress: ((Double) -> Void)?, completion: @escaping CallBack) {
        do {
            var request = try generateRequest(withParameters: parameters)
            handleRequest(request: &request)
            guard let uploadParameters = generateMultipartFormData(withParameters: parameters) else {
                completion(nil, BackendError.badRequest(reason: "no upload parameters"))
                return
            }
            guard let responseHandler = analysisResponse(withCompletion: completion) else { return }
            connection.upload(request: request, parameters: uploadParameters, progressHandler: progress, responseHandler: responseHandler)
        } catch {
            completion(nil, error)
            return
        }
    }
    
    func cancel() -> Bool {
        return connection.cancel()
    }
}

class RestAPI {
    
    class func setting(withUserID userID: String, ticket: String) {
        RestAPI.userID = userID
        RestAPI.ticket = ticket
    }
    
    static var userID: String!
    static var ticket: String!
    
    let connection = RestConnection()
    
    let apiType: Int
    
    init(apiType: Int) {
        self.apiType = apiType
    }
    
    var completion: CallBack?
    
    func generateRequest(withParameters parameters: Any?) throws -> URLRequest {
        throw BackendError.badRequest(reason: "")
    }
    
    func analysisResponse(withCompletion completion: @escaping CallBack) -> ResponseHandler? {
        return nil
    }
    
    func generateMultipartFormData(withParameters parameters: Any?) -> [UploadPartFormData]? {
        return nil
    }
    
    fileprivate func handleRequest(request: inout URLRequest) {
        
        if let deviceId = Host.current().localizedName {
            let encodedSet = CharacterSet.init(charactersIn: "!*'();:@&=+$,/?%#[]")
            let encodedString = deviceId.addingPercentEncoding(withAllowedCharacters: encodedSet.inverted)
            request.setValue(encodedString, forHTTPHeaderField: "deviceId")
        }
        
        let platformId = NXCommonUtils.getPlatformId()
        
        let clientId = NXCommonUtils.deviceID()
        
        request.setValue("\(platformId)", forHTTPHeaderField: "platformId")
        request.setValue(clientId, forHTTPHeaderField: "clientId")
        request.setValue(DEFAULT_TENANT_ID, forHTTPHeaderField: "tenantId")
    }
}

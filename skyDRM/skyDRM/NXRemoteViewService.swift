//
//  NXRemoteViewService.swift
//  skyDRM
//
//  Created by Eric (Zeng) Wang on 4/27/17.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

@objc protocol NXRemoteViewServiceDelegate: NSObjectProtocol {
    //unknow file path, so just fileName here.
    @objc optional func translateRemoteViewerProgress(fileName:String?, progress: Double)
    
    //@objc optional func translateRemoteViewerFinished(viewURL: String?, cookies: [String]?, duid: String?, error: Error?)
    
    @objc optional func translateRemoteViewerFinished(viewURL: String?, cookies: [String]?, owner: Bool, permissions: Int32, duid: String?, error: Error?)
}

class NXRemoteViewService {
    init(userID: String, ticket: String) {
        NXRemoteViewAPI.setting(withUserID: userID, ticket: ticket)
    }
    
    weak var delegate: NXRemoteViewServiceDelegate?
    
    //MARK: public Interface
    /**
     *  mark as Deprecated.
     **/
    func remoteViewer(userName: String, parentTenantId:String, parentTenantName: String, fileName: String, fileData:NSData){
        let parameter: [String: Any] = ["userName": userName,
                                        "tenantId": parentTenantId,
                                        "tenantName": parentTenantName,
                                        "fileName": fileName,
                                        "offset": "0"]
        
        let api = NXRemoteViewAPI(type: .viewVDS)
        
        let allParameter = ["fileData": fileData, "object": parameter] as [String : Any]
        
        let progress: (Double) -> Void = {
            progress in
            self.delegate?.translateRemoteViewerProgress!(fileName: fileName, progress: progress)
        }
        let completion: (Any?, Error?) -> Void = {
            response, error in
        
            var item: NXRemoteViewModel?
            if error == nil, let response = response as? NXRemoteViewResponse.viewVDSResponse {
                item = response.viewVDSModel
            }
            
            self.delegate?.translateRemoteViewerFinished!(viewURL: item?.viewerURL, cookies: item?.cookies, owner: item?.owner ?? false, permissions: item?.permissions ?? 0, duid: item?.duid, error: error)
        }
        
        api.uploadFile(withParameters: allParameter, progress: progress, completion: completion)
    }
    
    func viewRepo(param: NXViewRepoParam){
        let body: [String: Any] = ["repoId": param.repoId,
                                    "pathId": param.pathId,
                                    "pathDisplay": param.pathDisplay,
                                    "offset": "-480",
                                    "repoName": param.repoName,
                                    "repoType": param.repoType,
                                    "email": param.email,
                                    "tenantName": param.parentTenantName,
                                    "lastModifiedDate": param.lastModifiedDate,
                                    "operations": param.operations]
        let api = NXRemoteViewAPI(type: .viewRepo)
        let parameter = [RequestParameter.body: body]
        let completion: (Any?, Error?) -> Void = {
            response, error in
            
            var item: NXRemoteViewModel?
            if error == nil, let response = response as? NXRemoteViewResponse.viewRepoResponse {
                item = response.viewRepoModel
            }
            self.delegate?.translateRemoteViewerFinished!(viewURL: item?.viewerURL, cookies: item?.cookies, owner: item?.owner ?? false, permissions: item?.permissions ?? 0, duid: item?.duid, error: error)
        }
        api.sendRequest(withParameters: parameter, completion: completion)
    }
    
    func viewProject(param: NXViewProjectParam){
        let body: [String: Any] = ["projectId": param.projectId,
                                   "pathId": param.pathId,
                                   "pathDisplay": param.pathDisplay,
                                   "offset": param.offset,
                                   "email": param.email,
                                   "tenantName": param.parentTenantName,
                                   "lastModifiedDate": param.lastModifiedDate,
                                   "operations": param.operatios
                                    ]
        let api = NXRemoteViewAPI(type: .viewProject)
        let parameter = [RequestParameter.body: body]
        let completion: (Any?, Error?)->Void = {
            response, error in
            var item: NXRemoteViewModel?
            if error == nil, let response = response as? NXRemoteViewResponse.viewRepoResponse {
                item = response.viewRepoModel
            }
            self.delegate?.translateRemoteViewerFinished!(viewURL: item?.viewerURL, cookies: item?.cookies, owner: item?.owner ?? false, permissions: item?.permissions ?? 0, duid: item?.duid, error: error)
        }
        api.sendRequest(withParameters: parameter, completion: completion)
    }
}

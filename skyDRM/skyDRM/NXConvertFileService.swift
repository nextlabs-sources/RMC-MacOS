//
//  NXConvertFileService.swift
//  skyDRM
//
//  Created by xx-huang on 17/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

@objc protocol NXConvertFileServiceDelegate: NSObjectProtocol {
    
    @objc optional func convertFileFinished(fileData:Data?,fileLocalPath:String?,error: Error?)
}

class NXConvertFileService {
    init(userID: String, ticket: String) {
        ConvertFileRestAPI.setting(withUserID: userID, ticket: ticket)
    }
    
    weak var delegate: NXConvertFileServiceDelegate?
    
    //MARK: public Interface
    func convertFileWith(fileName: String,toFormat:String,fileData:NSData, destName: String){
        let parameter: [String: Any] = [RequestParameter.url: ["fileName": fileName,
                                                               "toFormat": toFormat,
                                                               "fileData":fileData]
        ]
        
        let api = ConvertFileRestAPI(type: .convertFile)
        api.sendRequest(withParameters: parameter, completion: {response, error in
            
            var fileData:Data?
            if error == nil,
                let responseObject = response as? ConvertFileResponse.converFileResponse
            {
                fileData = responseObject.resultData
            }
            
            DispatchQueue.global().async {
                 // do some task
                var path = NXCommonUtils.getConvertFileFolder()
                
                path = path?.appendingPathComponent(destName)
                
                if FileManager.default.fileExists(atPath: (path?.path)!)
                {
                    do {
                        try FileManager.default.removeItem(atPath: (path?.path)!)
                    }
                    catch let error as NSError {
                        Swift.print("remove file failed with : \(error)")
                    }
                }
                
                do {
                    try fileData?.write(to:path!)
                }
                catch let error as NSError {
                    Swift.print("convert file receive data  but write file fail with: \(error)")
                }

                DispatchQueue.main.async {
                    guard let delegate = self.delegate,
                        delegate.responds(to:#selector(NXConvertFileServiceDelegate.convertFileFinished(fileData:fileLocalPath:error:))) else {
                            return
                    }
                    delegate.convertFileFinished!(fileData:fileData,fileLocalPath:path?.path, error:error)
                    // update some UI
                }
            }
        })
    }
}

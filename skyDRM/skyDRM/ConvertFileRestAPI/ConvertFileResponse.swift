//
//  ConvertFileResponse.swift
//  skyDRM
//
//  Created by xx-huang on 17/03/2017.
//  Copyright © 2017 nextlabs. All rights reserved.
//

import Foundation

class ConvertFileResponse: RestResponse {
    
    override func responeObject(responseType: Int, response: HTTPURLResponse, representation: Any) -> Any? {
        guard let type = ConvertFileRestAPI.ConvertFileRestAPIType(rawValue: responseType) else {
            return nil
        }
        
        switch type {
        case .convertFile:
            return ConvertFileResponse.converFileResponse(response: response, representation: representation)
        }
    }
    
    struct converFileResponse: ResponseObjectSerializable {
        
        var resultData: Data
        
        init?(response: HTTPURLResponse, representation: Any) {
            guard let data = representation as? Data else {
                return nil
            }
            resultData = data
        }
    }
}

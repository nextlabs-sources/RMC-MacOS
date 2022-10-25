//
//  ODItemContentRequest+RangeDownload.swift
//  Test
//
//  Created by nextlabs on 2017/3/29.
//  Copyright © 2017年 nextlabs. All rights reserved.
//

import Foundation

extension ODItemContentRequest {
    func rangeDownload(range: NSRange, completionHandler: @escaping ODDownloadCompletionHandler) -> ODURLSessionDownloadTask? {
        let headers: [String: String] = ["Range": "bytes=\(range.location)-\(range.location+range.length-1)"]
        let request = self.request(withMethod: "Get", body: nil, headers:  headers)
//        request.setValue("bytes=\(range.location)-\(range.location+range.length-1)", forHTTPHeaderField: "Range")
        let task = ODURLSessionDownloadTask(request: request, client: self.client, completionHandler: completionHandler)
        task?.execute()
        return task
    }
}

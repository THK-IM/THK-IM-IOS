//
//  AVCacheRangeRequest.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/16.
//

import Foundation
import AVFoundation
import Alamofire
import CocoaLumberjack

typealias AVRequestCallBlack = (_ success: Bool, _ requestRange: String, _ requestUrl: String, _ data: Data?, _ responseRange: String?, _ responseType :String?) -> Void

class AVCacheRangeRequest {
    
    private var downloadRequest: DownloadRequest?
    var requestRange: String
    var originRequestRange: String
    var urlString: String
    private var requestCallBlack: AVRequestCallBlack?
    
    init(_ requestRange: String, _ originRequestRange: String, _ urlString: String, _ requestCallBlack: @escaping AVRequestCallBlack) {
        self.requestRange = requestRange
        self.originRequestRange = originRequestRange
        self.urlString = urlString
        self.requestCallBlack = requestCallBlack
    }
    
    func startDownload() {
        var headers = HTTPHeaders()
        if (AVCacheManager.shared.delegate != nil) {
            let addHeaders = AVCacheManager.shared.delegate!.header(url: urlString)
            if (addHeaders != nil) {
                for addHeader in addHeaders! {
                    headers.add(HTTPHeader(name: addHeader.key, value: addHeader.value))
                }
            }
        }
        if self.requestRange != "" {
            headers.add(HTTPHeader(name: "Range", value: self.requestRange))
        }
        
        self.downloadRequest = AF.download(self.urlString, headers: headers)
            .redirect(using: Redirector(behavior: .follow))
            .responseData { [weak self] response in
                DispatchQueue.global().async {
                    guard let sf = self else {
                        return
                    }
                    switch response.result {
                    case .success:
                        let range = response.response?.headers["Content-Range"]
                        let type = response.response?.headers["Content-Type"]
                        let data = response.value
                        sf.requestCallBlack?(true, sf.originRequestRange, sf.urlString, data, range, type)
                        break
                    case .failure:
                        sf.requestCallBlack?(false, sf.originRequestRange, sf.urlString, nil, nil, nil)
                        break
                    }
                }
        }
    }
    
    func cancel() {
        if (self.downloadRequest != nil) {
            if (!self.downloadRequest!.isCancelled) {
                self.downloadRequest!.cancel()
            }
        }
        self.requestCallBlack = nil
    }
    
    
    
    
}
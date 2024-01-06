//
//  IMAVCacheProtocol.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/12.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

public class IMAVCacheProtocol: AVCacheProtocol {
    
    private var token: String = ""
    private var endpoint: String = ""
    
    public init(token: String, endpoint: String) {
        self.token = token
        self.endpoint = endpoint
    }
    
    public func getToken() -> String {
        return self.token
    }
    
    public func getEndpoint() -> String {
        return self.endpoint
    }
    
    public func maxCacheSize() -> Int64 {
        return 5 * 1024 * 1024
    }
    
    public func maxCacheCount() -> Int {
        return 200
    }
    
    public func header(url: String) -> [String : String?]? {
        if url.hasPrefix(self.endpoint) {
            return [
                APITokenInterceptor.tokenKey: self.token,
                APITokenInterceptor.clientVersionKey: AppUtils.getVersion(),
                APITokenInterceptor.platformKey: "IOS",
            ]
        } else {
            return [
                APITokenInterceptor.tokenKey: nil,
                APITokenInterceptor.clientVersionKey: nil,
                APITokenInterceptor.platformKey: nil,
            ]
        }
    }
    
    public func cacheDirPath() -> String {
        return NSTemporaryDirectory() + "THK_IM_CACHE/video"
    }
    
    public func cacheKey(url: String) -> String {
        if url.hasSuffix(self.endpoint) {
            let urlComponents = URLComponents(string: url)
            if (urlComponents != nil && urlComponents!.queryItems != nil) {
                for it in urlComponents!.queryItems! {
                    if it.name == "id" && it.value != nil {
                        return it.value!
                    }
                }
            }
        }
        return url
    }
    
    
}

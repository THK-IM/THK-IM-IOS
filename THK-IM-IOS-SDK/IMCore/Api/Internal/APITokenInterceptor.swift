//
//  APITokenInterceptor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import Moya

public class APITokenInterceptor: PluginType {
    
    private var token: String?
    
    static let tokenKey = "Authorization"
    static let versionKey = "Version"
    static let platformKey = "Platform"
    static let timezoneKey = "TimeZone"
    static let deviceKey = "Device"
    static let languageKey = "Accept-Language"
    
    private var validEndpoints: Set<String>
    
    init(token: String? = nil) {
        self.token = token
        self.validEndpoints = Set()
    }
    
    public func updateToken(token: String) {
        self.token = token
    }
    
    public func addValidEndpoint(endpoint: String) {
        self.validEndpoints.insert(endpoint)
    }
    
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var newRequest = request
        let isValidEndpoint = isValidEndpoint(url: request.url?.absoluteString ?? "")
        if (isValidEndpoint) {
            newRequest.setValue(AppUtils.getDeviceName(), forHTTPHeaderField: APITokenInterceptor.deviceKey)
            newRequest.setValue(AppUtils.getTimezone(), forHTTPHeaderField: APITokenInterceptor.timezoneKey)
            newRequest.setValue(AppUtils.getVersion(), forHTTPHeaderField: APITokenInterceptor.versionKey)
            newRequest.setValue(AppUtils.getLanguage(), forHTTPHeaderField: APITokenInterceptor.languageKey)
            newRequest.setValue("IOS", forHTTPHeaderField: APITokenInterceptor.platformKey)
            if (token != nil) {
                let value = "Bearer \(token!)"
                newRequest.setValue(value, forHTTPHeaderField: APITokenInterceptor.tokenKey)
            }
        } else {
            newRequest.headers.remove(name: APITokenInterceptor.deviceKey)
            newRequest.headers.remove(name: APITokenInterceptor.timezoneKey)
            newRequest.headers.remove(name: APITokenInterceptor.platformKey)
            newRequest.headers.remove(name: APITokenInterceptor.languageKey)
            newRequest.headers.remove(name: APITokenInterceptor.versionKey)
            newRequest.headers.remove(name: APITokenInterceptor.tokenKey)
        }
        return newRequest
    }
    
    func isValidEndpoint(url: String) -> Bool {
        for validEndpoint in validEndpoints {
            if (url.starts(with: validEndpoint)) {
                return true
            }
        }
        return false
    }
    
}

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
    static let clientVersionKey = "Client-Version"
    static let platformKey = "Client-Platform"
    
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
            newRequest.setValue(AppUtils.getVersion(), forHTTPHeaderField: APITokenInterceptor.clientVersionKey)
            if (token != nil) {
                let value = "Bearer \(token!)"
                newRequest.setValue(value, forHTTPHeaderField: APITokenInterceptor.tokenKey)
            }
            newRequest.setValue("IOS", forHTTPHeaderField: APITokenInterceptor.platformKey)
        } else {
            newRequest.headers.remove(name: APITokenInterceptor.clientVersionKey)
            newRequest.headers.remove(name: APITokenInterceptor.tokenKey)
            newRequest.headers.remove(name: APITokenInterceptor.platformKey)
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

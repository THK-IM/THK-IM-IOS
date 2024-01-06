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
    
    private let tokenKey = "Authorization"
    private let clientVersionKey = "Client-Version"
    private let platformKey = "Client-Platform"
    
    init(token: String? = nil) {
        self.token = token
    }
    
    public func updateToken(token: String) {
        self.token = token
    }
    
    public func prepare(_ request: URLRequest, target: TargetType) -> URLRequest {
        var newRequest = request
        if let appVersion = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String {
            newRequest.setValue(appVersion, forHTTPHeaderField: clientVersionKey)
        } else {
            newRequest.setValue("0.0.0", forHTTPHeaderField: clientVersionKey)
        }
        if (token != nil) {
            let value = "Bearer \(token!)"
            newRequest.setValue(value, forHTTPHeaderField: tokenKey)
        }
        newRequest.setValue("IOS", forHTTPHeaderField: platformKey)
        return newRequest
    }
    
}

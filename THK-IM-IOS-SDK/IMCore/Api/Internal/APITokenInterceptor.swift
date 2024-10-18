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

    public init(token: String? = nil) {
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
        if isValidEndpoint {
            newRequest.setValue(
                AppUtils.getDeviceName(), forHTTPHeaderField: APITokenInterceptor.deviceKey)
            newRequest.setValue(
                AppUtils.getTimezone(), forHTTPHeaderField: APITokenInterceptor.timezoneKey)
            newRequest.setValue(
                AppUtils.getVersion(), forHTTPHeaderField: APITokenInterceptor.versionKey)
            newRequest.setValue(
                AppUtils.getLanguage(), forHTTPHeaderField: APITokenInterceptor.languageKey)
            newRequest.setValue("IOS", forHTTPHeaderField: APITokenInterceptor.platformKey)
            if token != nil {
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
        if let coder = IMCoreManager.shared.crypto {
            if let requestBodyString = String(data: newRequest.httpBody ?? Data(), encoding: .utf8)
            {
                if requestBodyString.count > 0 {
                    if let encryptedString = coder.encrypt(requestBodyString) {
                        newRequest.httpBody = encryptedString.data(using: .utf8)
                    }
                }
            }
        }
        return newRequest
    }

    public func process(_ result: Result<Response, MoyaError>, target: TargetType) -> Result<
        Response, MoyaError
    > {
        switch result {
        case .success(let response):
            if let coder = IMCoreManager.shared.crypto {
                // 尝试解密response.data
                if let responseText = String(data: response.data, encoding: .utf8) {
                    let decryptedData = coder.decrypt(responseText)
                    // 使用解密后的数据创建一个新的Response对象
                    let newResponse = Response(
                        statusCode: response.statusCode,
                        data: decryptedData?.data(using: .utf8) ?? Data())
                    return .success(newResponse)
                } else {
                    return .success(response)
                }
            } else {
                return .success(response)
            }

        case .failure:
            // 如果原始结果是错误，直接返回这个错误
            return result
        }
    }

    func isValidEndpoint(url: String) -> Bool {
        for validEndpoint in validEndpoints {
            if url.starts(with: validEndpoint) {
                return true
            }
        }
        return false
    }

}

//
//  DataRepository.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Moya
import UIKit

public class DataRepository: NSObject {

    static let shared = DataRepository()

    lazy var app: UIApplication = {
        return _app!
    }()
    lazy var apiTokenInterceptor: APITokenInterceptor = {
        return _apiTokenInterceptor!
    }()
    lazy var userApi: MoyaProvider<UserApi> = {
        return _userApi!
    }()
    lazy var contactApi: MoyaProvider<ContactApi> = {
        return _contactApi!
    }()
    lazy var groupApi: MoyaProvider<GroupApi> = {
        return _groupApi!
    }()

    private var _app: UIApplication?
    private var _apiTokenInterceptor: APITokenInterceptor?
    private var _userApi: MoyaProvider<UserApi>?
    private var _contactApi: MoyaProvider<ContactApi>?
    private var _groupApi: MoyaProvider<GroupApi>?

    func initApplication(app: UIApplication) {
        self._app = app
        let token = self.getUserToken()
        self._apiTokenInterceptor = APITokenInterceptor(token: token)
        self._apiTokenInterceptor?.addValidEndpoint(endpoint: getApiHost(type: "user"))
        self._apiTokenInterceptor?.addValidEndpoint(endpoint: getApiHost(type: "contact"))
        self._apiTokenInterceptor?.addValidEndpoint(endpoint: getApiHost(type: "group"))
        self._apiTokenInterceptor?.addValidEndpoint(endpoint: getApiHost(type: "msg"))
        self._userApi = MoyaProvider<UserApi>(plugins: [_apiTokenInterceptor!])
        self._contactApi = MoyaProvider<ContactApi>(plugins: [_apiTokenInterceptor!])
        self._groupApi = MoyaProvider<GroupApi>(plugins: [_apiTokenInterceptor!])
    }

    func updateToken(token: String) {
        self._apiTokenInterceptor?.updateToken(token: token)
    }

    func getUserToken() -> String? {
        let key = "/UserInfo/Token"
        let value = UserDefaults.standard.object(forKey: key)
        let token = value == nil ? nil : (value as! String)
        return token
    }

    func getUserId() -> Int64? {
        let key = "/UserInfo/UserId"
        let value = UserDefaults.standard.object(forKey: key)
        let userId = value == nil ? nil : (value as! Int64)
        return userId
    }

    func getUser() -> UserVo? {
        guard let userId = getUserId() else {
            return nil
        }
        let key = "/UserInfo/User:\(userId)"
        let value = UserDefaults.standard.object(forKey: key)
        let userJson = value == nil ? nil : (value as! Data)
        let user = try? JSONDecoder().decode(UserVo.self, from: userJson ?? Data())
        return user
    }

    func saveUserInfo(token: String, userVo: UserVo) {
        let tokenKey = "/UserInfo/Token"
        UserDefaults.standard.setValue(token, forKey: tokenKey)
        let userIdKey = "/UserInfo/UserId"
        UserDefaults.standard.setValue(userVo.id, forKey: userIdKey)
        let userKey = "/UserInfo/User:\(userVo.id)"
        let userData = try? JSONEncoder().encode(userVo)
        UserDefaults.standard.setValue(userData, forKey: userKey)
        UserDefaults.standard.synchronize()
    }

    func getApiHost(type: String) -> String {
        if type == "user" {
            return "http://user-api.thkim.com"
        } else if type == "contact" {
            return "http://contact-api.thkim.com"
        } else if type == "group" {
            return "http://group-api.thkim.com"
        } else if type == "msg" {
            return "http://msg-api.thkim.com"
        } else if type == "websocket" {
            return "ws://ws.thkim.com/ws"
        }
        return ""
    }
}

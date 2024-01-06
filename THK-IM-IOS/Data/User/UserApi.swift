//
//  UserApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

import Moya

enum UserApi {
    /// 注册
    case register(_ req: RegisterReq)
    /// 通过token登录
    case loginByToken(_ req: TokenLoginReq)
    /// 查询自己信息
    case queryUser(_ id: Int64)
    /// 通过displayId搜索用户
    case searchUserByDisplayId(_ displayId: String)
}


extension UserApi: TargetType {
    
    var headers: [String : String]? {
        return nil
    }
    
    var baseURL: URL {
        return URL.init(string: "\(DataRepository.shared.getApiHost(type: "user"))")!
    }
    
    var path: String {
        switch self {
        case .register:
            return "/user/register"
        case .loginByToken:
            return "/user/login/token"
        case let .queryUser(id):
            return "/user/query/\(id)"
        case .searchUserByDisplayId:
            return "/user/user"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .register:
            return .post
        case .loginByToken:
            return .post
        case .queryUser:
            return .get
        case .searchUserByDisplayId:
            return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case let .register(req):
            return .requestJSONEncodable(req)
        case let .loginByToken(req):
            return .requestJSONEncodable(req)
        case .queryUser:
            return .requestPlain
        case let .searchUserByDisplayId(displayId):
            let urlParameters = ["display_id": displayId] as [String : Any]
            return .requestParameters(parameters: urlParameters, encoding: URLEncoding.queryString)
        }
    }
    
    var validationType: Moya.ValidationType {
        return .none
    }
    
}

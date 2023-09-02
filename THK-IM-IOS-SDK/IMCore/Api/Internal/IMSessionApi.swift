//
//  IMSessionApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/28.
//

import Foundation

import Moya

enum IMSessionApi {
    /// 创建会话
    case createSession(_ bean: CreateSessionBean)
    /// 查询最近会话列表
    case queryLatestSession(_ uId: Int64, _ offset :Int, _ count: Int, _ mTime: Int64)
    /// 查询单个会话
    case querySession(_ uId: Int64, _ sessionId: Int64)
}


extension IMSessionApi: TargetType {
    
    var baseURL: URL {
        return URL.init(string: "\(IMCoreManager.shared.api.endpoint())")!
    }
    
    var path: String {
        switch self {
        case .createSession:
            return "/session"
        case .queryLatestSession:
            return "/session/latest"
        case let .querySession(uId, sessionId):
            return "/user_session/\(uId)/\(sessionId)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .createSession:
            return .post
        case .queryLatestSession:
            return .get
        case .querySession:
            return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case let .createSession(bean):
            return .requestJSONEncodable(bean)
        case let .queryLatestSession(uId, offset, count, mTime):
            let urlParameters = ["u_id": uId, "offset": offset, "size": count, "m_Time": mTime] as [String : Any]
            return .requestParameters(parameters: urlParameters, encoding: URLEncoding.queryString)
        case .querySession:
            return .requestPlain
        }
    }
    
    var validationType: Moya.ValidationType {
        return .none
    }
    
    var headers: [String : String]? {
        return nil
    }
}

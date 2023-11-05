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
    /// 删除session
    case deleteSession(_ uId: Int64, _ sessionId: Int64)
    /// 更新session
    case updateSession(_ bean: UpdateSessionBean)
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
        case let .deleteSession(uId, sessionId):
            return "/user_session/\(uId)/\(sessionId)"
        case .updateSession:
            return "/user_session"
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
        case .deleteSession:
            return .delete
        case .updateSession:
            return .put
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
        case .deleteSession:
            return .requestPlain
        case let .updateSession(bean):
            return .requestJSONEncodable(bean)
        }
    }
    
    var validationType: Moya.ValidationType {
        return .none
    }
    
    var headers: [String : String]? {
        return nil
    }
}

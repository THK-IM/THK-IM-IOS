//
//  IMSessionApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/28.
//

import Foundation

import Moya

enum IMSessionApi {
    /// 查询最近会话列表
    case queryLatestSession(_ uId: Int64, _ offset :Int, _ count: Int, _ mTime: Int64, _ types: Set<Int>?)
    /// 查询单个会话
    case querySession(_ uId: Int64, _ sessionId: Int64)
    /// 查询单个会话
    case querySessionByEntityId(_ uId: Int64, _ entityId: Int64, _ type: Int)
    /// 删除session
    case deleteSession(_ uId: Int64, _ sessionId: Int64)
    /// 更新session
    case updateSession(_ req: UpdateSessionVo)
}


extension IMSessionApi: TargetType {
    
    var baseURL: URL {
        return URL.init(string: "\(IMCoreManager.shared.api.getEndpoint())")!
    }
    
    var path: String {
        switch self {
        case .queryLatestSession:
            return "/session/latest"
        case let .querySession(uId, sessionId):
            return "/user_session/\(uId)/\(sessionId)"
        case .querySessionByEntityId:
            return "/user_session"
        case let .deleteSession(uId, sessionId):
            return "/user_session/\(uId)/\(sessionId)"
        case .updateSession:
            return "/user_session"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .queryLatestSession:
            return .get
        case .querySession:
            return .get
        case .querySessionByEntityId:
            return .get
        case .deleteSession:
            return .delete
        case .updateSession:
            return .put
        }
    }
    
    var task: Moya.Task {
        switch self {
        case let .queryLatestSession(uId, offset, count, mTime, types):
            let urlParameters = ["u_id": uId, "offset": offset, "size": count, "m_Time": mTime, "types": types ?? ""] as [String : Any]
            return .requestParameters(parameters: urlParameters, encoding: URLEncoding.queryString)
        case .querySession:
            return .requestPlain
        case let .querySessionByEntityId(uId, entityId, type):
            let urlParameters = ["u_id": uId, "entity_id": entityId, "type": type] as [String : Any]
            return .requestParameters(parameters: urlParameters, encoding: URLEncoding.queryString)
        case .deleteSession:
            return .requestPlain
        case let .updateSession(req):
            return .requestJSONEncodable(req)
        }
    }
    
    var validationType: Moya.ValidationType {
        return .none
    }
    
    var headers: [String : String]? {
        return nil
    }
}

//
//  IMMessageApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation

import Moya

enum IMMessageApi {
    /// 发送消息
    case sendMsg(_ bean: MessageBean)
    /// 查询最新消息
    case queryLatestMsg(_ uId: Int64, _ offset :Int, _ count: Int, _ cTime: Int64)
    /// 消息ack
    case ackMsgs(_ bean: AckMsgBean)
    /// 已读消息
    case readMsgs(_ bean: ReadMsgBean)
    /// 撤回消息
    case revokeMsg(_ bean: RevokeMsgBean)
    /// 删除消息
    case deleteMsgs(_ bean: DeleteMsgBean)
}


extension IMMessageApi: TargetType {
    
    var baseURL: URL {
        return URL.init(string: "\(IMCoreManager.shared.api.getEndpoint())")!
    }
    
    var path: String {
        switch self {
        case .sendMsg:
            return "/message"
        case .queryLatestMsg:
            return "/message/latest"
        case .ackMsgs:
            return "/message/ack"
        case .readMsgs:
            return "/message/read"
        case .revokeMsg:
            return "/message/revoke"
        case .deleteMsgs:
            return "/message"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .sendMsg:
            return .post
        case .queryLatestMsg:
            return .get
        case .ackMsgs:
            return .post
        case .readMsgs:
            return .post
        case .revokeMsg:
            return .post
        case .deleteMsgs:
            return .delete
        }
    }
    
    var task: Moya.Task {
        switch self {
        case let .sendMsg(bean):
            return .requestJSONEncodable(bean)
        case let .queryLatestMsg(uId, offset, count, cTime):
            let urlParameters = ["u_id": uId, "offset": offset, "count": count, "c_time": cTime] as [String : Any]
            return .requestParameters(parameters: urlParameters, encoding: URLEncoding.queryString)
        case let .ackMsgs(bean):
            return .requestJSONEncodable(bean)
        case let .readMsgs(bean):
            return .requestJSONEncodable(bean)
        case let .revokeMsg(bean):
            return .requestJSONEncodable(bean)
        case let .deleteMsgs(bean):
            return .requestJSONEncodable(bean)
        }
    }
    
    var validationType: Moya.ValidationType {
        return .none
    }
    
    var headers: [String : String]? {
        var headers = [String: String]()
        headers["Token"] = "\(IMCoreManager.shared.api.getToken())"
        return headers
    }
}

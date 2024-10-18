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
    case sendMsg(_ req: MessageVo)
    /// 查询最新消息
    case queryLatestMsg(_ uId: Int64, _ offset: Int, _ count: Int, _ cTime: Int64)
    /// 消息ack
    case ackMsgs(_ req: AckMsgVo)
    /// 已读消息
    case readMsgs(_ req: ReadMsgVo)
    /// 撤回消息
    case revokeMsg(_ req: RevokeMsgVo)
    /// 重编辑消息
    case reeditMsg(_ req: ReeditMsgVo)
    /// 转发消息
    case forwardMsg(_ req: ForwardMessageVo)
    /// 删除消息
    case deleteMsgs(_ req: DeleteMsgVo)
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
        case .reeditMsg:
            return "/message/reedit"
        case .forwardMsg:
            return "/message/forward"
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
        case .reeditMsg:
            return .post
        case .forwardMsg:
            return .post
        case .deleteMsgs:
            return .delete
        }
    }

    var task: Moya.Task {
        switch self {
        case let .sendMsg(req):
            return .requestJSONEncodable(req)
        case let .queryLatestMsg(uId, offset, count, cTime):
            let urlParameters =
                ["u_id": uId, "offset": offset, "count": count, "c_time": cTime] as [String: Any]
            return .requestParameters(parameters: urlParameters, encoding: URLEncoding.queryString)
        case let .ackMsgs(req):
            return .requestJSONEncodable(req)
        case let .readMsgs(req):
            return .requestJSONEncodable(req)
        case let .revokeMsg(req):
            return .requestJSONEncodable(req)
        case let .reeditMsg(req):
            return .requestJSONEncodable(req)
        case let .forwardMsg(req):
            return .requestJSONEncodable(req)
        case let .deleteMsgs(req):
            return .requestJSONEncodable(req)
        }
    }

    var validationType: Moya.ValidationType {
        return .none
    }

    var headers: [String: String]? {
        return nil
    }
}

//
//  MessageVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation


public class MessageVo: Codable {
    var clientId: Int64 = 0
    var fUId: Int64 = 0
    var sessionId : Int64 = 0
    var msgId: Int64  = 0
    var type: Int = 0
    var body: String = ""
    var status: Int? = nil
    var rMsgId: Int64? = nil
    var atUsers: String? = nil
    var extData: String? = nil
    var cTime: Int64 = 0
    
    init(msg: Message) {
        self.clientId = msg.id
        self.fUId = msg.fromUId
        self.sessionId = msg.sessionId
        self.msgId = msg.msgId
        self.type = msg.type
        self.body = msg.content ?? ""
        self.rMsgId = msg.referMsgId
        self.atUsers = msg.atUsers
        self.extData = msg.extData
        self.cTime = msg.cTime
    }
    
    required public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clientId = try container.decodeIfPresent(Int64.self, forKey: .clientId) ?? 0
        self.fUId = try container.decodeIfPresent(Int64.self, forKey: .fUId) ?? 0
        self.sessionId = try container.decodeIfPresent(Int64.self, forKey: .sessionId) ?? 0
        self.msgId = try container.decodeIfPresent(Int64.self, forKey: .msgId) ?? 0
        self.type = try container.decodeIfPresent(Int.self, forKey: .type) ?? 0
        self.body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        self.rMsgId = try container.decodeIfPresent(Int64.self, forKey: .rMsgId)
        self.status = try container.decodeIfPresent(Int.self, forKey: .status) ?? 0
        self.atUsers = try container.decodeIfPresent(String.self, forKey: .atUsers)
        self.extData = try container.decodeIfPresent(String.self, forKey: .extData)
        self.cTime = try container.decodeIfPresent(Int64.self, forKey: .cTime) ?? 0
    }
    
    init(clientId: Int64, fUId: Int64, sessionId: Int64, msgId: Int64, type: Int, body: String, rMsgId: Int64? = nil, atUsers: String? = nil, cTime: Int64) {
        self.clientId = clientId
        self.fUId = fUId
        self.sessionId = sessionId
        self.msgId = msgId
        self.type = type
        self.body = body
        self.rMsgId = rMsgId
        self.atUsers = atUsers
        self.cTime = cTime
    }
    
    enum CodingKeys: String, CodingKey {
        case clientId = "c_id"
        case fUId = "f_u_id"
        case sessionId = "s_id"
        case msgId = "msg_id"
        case type = "type"
        case body = "body"
        case status = "status"
        case rMsgId = "r_msg_id"
        case atUsers = "at_users"
        case extData = "ext_data"
        case cTime = "c_time"
    }
    
    func toMessage() -> Message {
        var oprStatus = self.status
        if (oprStatus == nil) {
            oprStatus = MsgOperateStatus.Init.rawValue
        }
        let message = Message(
            id: self.clientId, sessionId: self.sessionId, fromUId: self.fUId, msgId: self.msgId,
            type: self.type, content: self.body, data: nil, sendStatus: MsgSendStatus.Success.rawValue,
            operateStatus: oprStatus!, referMsgId: self.rMsgId, extData: self.extData, atUsers: self.atUsers,
            cTime: self.cTime, mTime: self.cTime)
        return message
    }
}

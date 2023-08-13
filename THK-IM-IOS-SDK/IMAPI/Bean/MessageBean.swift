//
//  MessageBean.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation


class MessageBean: Codable {
    var clientId: Int64 = 0
    var fUId: Int64 = 0
    var sessionId : Int64 = 0
    var msgId: Int64  = 0
    var type: Int = 0
    var body: String = ""
    var rMsgId: Int64? = nil
    var atUsers: String? = nil
    var cTime: Int64 = 0
    
    init() {
        
    }
    
    init(msg: Message) {
        self.clientId = msg.id
        self.fUId = msg.fUId
        self.sessionId = msg.sid
        self.msgId = msg.msgId
        self.type = msg.type
        self.body = msg.content
        self.rMsgId = msg.rMsgId
        self.atUsers = msg.atUsers
        self.cTime = msg.cTime
    }
    
    required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.clientId = try container.decodeIfPresent(Int64.self, forKey: .clientId) ?? 0
        self.fUId = try container.decodeIfPresent(Int64.self, forKey: .fUId) ?? 0
        self.sessionId = try container.decodeIfPresent(Int64.self, forKey: .sessionId) ?? 0
        self.msgId = try container.decodeIfPresent(Int64.self, forKey: .msgId) ?? 0
        self.type = try container.decodeIfPresent(Int.self, forKey: .type) ?? 0
        self.body = try container.decodeIfPresent(String.self, forKey: .body) ?? ""
        self.rMsgId = try container.decodeIfPresent(Int64.self, forKey: .rMsgId)
        self.atUsers = try container.decodeIfPresent(String.self, forKey: .atUsers)
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
        case clientId = "client_id"
        case fUId = "f_uid"
        case sessionId = "session_id"
        case msgId = "msg_id"
        case type = "type"
        case body = "body"
        case rMsgId = "r_msg_id"
        case atUsers = "at_users"
        case cTime = "c_time"
    }
    
    func toMessage() -> Message {
        let message = Message()
        message.id = self.clientId
        message.sid = self.sessionId
        message.msgId = self.msgId
        message.type = self.type
        message.fUId = self.fUId
        message.atUsers = self.atUsers
        message.rMsgId = self.rMsgId
        message.content = self.body
        message.mTime = self.cTime
        message.cTime = self.cTime
        return message
    }
}

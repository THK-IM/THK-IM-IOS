//
//  Message.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/13.
//

import Foundation
import WCDBSwift

public final class Message: TableCodable, Hashable {
    
    public static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
    
    // 消息id(客户端)
    var id: Int64 = 0
    // sessionId
    var sessionId : Int64 = 0
    // 发件人id
    var fromUId: Int64 = 0
    // 消息id(服务端)
    var msgId: Int64 = 0
    // 消息类型
    var type: Int = 0
    // 消息内容, 服务端数据
    var content: String?
    // 消息内容 本地数据 json格式
    var data: String?
    // 消息发送状态,值标记
    var sendStatus: Int = MsgSendStatus.Init.rawValue
    // 消息操作状态 ack/read/revoke/update bit位标记
    var operateStatus: Int = MsgOperateStatus.Init.rawValue
    // 已读用户 uId1#uId2
    var rUsers: String? = nil
    // 引用消息Id
    var referMsgId: Int64? = nil
    // 消息@人列表, uId1#uId2 || all所有人
    var atUsers: String? = nil
    // 消息创建时间
    var cTime: Int64
    // 消息最近修改时间
    var mTime: Int64
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = Message
        public static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindMultiPrimary(id, sessionId, fromUId, onConflict: ConflictAction.Replace)
            BindMultiUnique(sessionId, msgId, onConflict: ConflictAction.Replace)
            BindIndex(sessionId, cTime, namedWith: "message_session_id_create_time_index", isUnique: false)
        }
        case id = "id"
        case sessionId = "session_id"
        case fromUId = "from_u_id"
        case msgId = "msg_id"
        case type = "type"
        case content = "content"
        case sendStatus = "send_status"
        case operateStatus = "opr_status"
        case referMsgId = "r_msg_id"
        case atUsers = "at_users"
        case data = "data"
        case cTime = "c_time"
        case mTime = "m_time"
    }
    
    public var isAutoIncrement: Bool = false // 用于定义是否使用自增的方式插入
    
    init(id: Int64, sessionId: Int64, fromUId: Int64, msgId: Int64, type: Int, content: String?, data: String?, 
         sendStatus: Int, operateStatus: Int, rUsers: String? = nil, referMsgId: Int64? = nil,
         atUsers: String? = nil, cTime: Int64, mTime: Int64) {
        self.id = id
        self.sessionId = sessionId
        self.fromUId = fromUId
        self.msgId = msgId
        self.type = type
        self.content = content
        self.data = data
        self.sendStatus = sendStatus
        self.operateStatus = operateStatus
        self.rUsers = rUsers
        self.referMsgId = referMsgId
        self.atUsers = atUsers
        self.cTime = cTime
        self.mTime = mTime
    }
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
}
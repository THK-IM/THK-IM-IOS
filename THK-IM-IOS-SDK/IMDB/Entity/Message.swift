//
//  Message.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/13.
//

import Foundation
import WCDBSwift

public final class Message: Hashable, TableCodable {
    
    var id: Int64 = 0
    var fUId: Int64 = 0
    var sid : Int64 = 0
    var msgId: Int64 = 0
    var type: Int = 0
    var content: String = ""
    var status: Int = MsgStatus.Init.rawValue
    var extData: String? = nil
    var rMsgId: Int64? = nil
    var atUsers: String? = nil
    var cTime: Int64 = 0
    var mTime: Int64 = 0
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = Message
        public static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindMultiPrimary(id, fUId, onConflict: ConflictAction.Ignore)
            BindMultiUnique(sid, msgId, onConflict: ConflictAction.Ignore)
            BindIndex(sid, cTime, namedWith: "_message_sid_ctime_index", isUnique: false)
        }
        case id = "id"
        case fUId = "f_uid"
        case sid = "sid"
        case msgId = "msg_id"
        case type = "type"
        case content = "content"
        case status = "status"
        case extData = "ext_data"
        case rMsgId = "r_msg_id"
        case atUsers = "at_users"
        case cTime = "c_time"
        case mTime = "m_time"
    }
    
    public var isAutoIncrement: Bool = false // 用于定义是否使用自增的方式插入
    
    
    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
    
    public static func == (lhs: Message, rhs: Message) -> Bool {
        return lhs.id == rhs.id
    }
    
}

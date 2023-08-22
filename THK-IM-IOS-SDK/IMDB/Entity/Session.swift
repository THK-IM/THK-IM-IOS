//
//  Message.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/14.
//

import Foundation
import WCDBSwift

public final class Session: TableCodable {
    // sessionId
    var id: Int64 = 0
    // session类型
    var type: Int = 0
    // session对象id, 单聊时为对方id, 群聊时为群id
    var entityId : Int64 = 0
    // session状态
    var status: Int
    // 未读数
    var unreadCount: Int = 0
    // 草稿
    var draft: String?
    // 最近一条消息
    var lastMsg: String? = nil
    // 置顶时间戳
    var topTimestamp: Int64? = 0
    // 自定义扩展数据 推荐使用json结构存储
    var extData: String? = nil
    // 消息创建时间
    var cTime: Int64
    // 消息最近修改时间
    var mTime: Int64
    
    public var isAutoIncrement: Bool = false // 用于定义是否使用自增的方式插入
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = Session
        public static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true)
            BindMultiUnique(type, entityId, onConflict: ConflictAction.Ignore)
            BindIndex(type, entityId, namedWith: "session_id_type_entity_index", isUnique: true)
        }
        case id = "id"
        case type = "type"
        case entityId = "entity_id"
        case status = "status"
        case unreadCount = "unread_count"
        case draft = "draft"
        case lastMsg = "last_msg"
        case topTimestamp = "top_timestamp"
        case extData = "ext_data"
        case cTime = "c_time"
        case mTime = "m_time"
    }
    
    
    init(id: Int64, type: Int, entityId: Int64, status: Int, unreadCount: Int, draft: String? = nil, lastMsg: String? = nil, topTimestamp: Int64? = nil, extData: String? = nil, cTime: Int64, mTime: Int64) {
        self.id = id
        self.type = type
        self.entityId = entityId
        self.status = status
        self.unreadCount = unreadCount
        self.draft = draft
        self.lastMsg = lastMsg
        self.topTimestamp = topTimestamp
        self.extData = extData
        self.cTime = cTime
        self.mTime = mTime
    }
    
}

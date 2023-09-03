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
    // session名称
    var name: String = ""
    // session remark
    var remark: String = ""
    // 禁言标记位 2^0 全员禁言 2^1 本人禁言
    var mute: Int = 0
    // 角色 1 成员 2 管理员 3 超级管理员 4 拥有者
    var role: Int = 0
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
            BindMultiUnique(type, entityId, onConflict: ConflictAction.Replace)
        }
        case id = "id"
        case type = "type"
        case entityId = "entity_id"
        case name = "name"
        case remark = "remark"
        case mute = "mute"
        case role = "role"
        case status = "status"
        case unreadCount = "unread_count"
        case draft = "draft"
        case lastMsg = "last_msg"
        case topTimestamp = "top_timestamp"
        case extData = "ext_data"
        case cTime = "c_time"
        case mTime = "m_time"
    }
    
    
    init(id: Int64, type: Int, entityId: Int64, name: String, remark: String, mute: Int, role: Int, status: Int,
         unreadCount: Int, draft: String? = nil, lastMsg: String? = nil, topTimestamp: Int64? = nil,
         extData: String? = nil, cTime: Int64, mTime: Int64) {
        self.id = id
        self.type = type
        self.entityId = entityId
        self.name = name
        self.remark = remark
        self.mute = mute
        self.role = role
        self.status = status
        self.unreadCount = unreadCount
        self.draft = draft
        self.lastMsg = lastMsg
        self.topTimestamp = topTimestamp
        self.extData = extData
        self.cTime = cTime
        self.mTime = mTime
    }
    
    public static func emptySession() -> Session {
        return Session(
            id: 0, type: 0, entityId: 0, name: "", remark: "", mute: 0, role: 0,
            status: 0, unreadCount: 0, cTime: 0, mTime: 0
        )
    }
    
}

//
//  Session.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/14.
//

import Foundation
import WCDBSwift

public final class Session: TableCodable {
    // sessionId
    public var id: Int64 = 0
    // 父sessionId
    public var parentId: Int64 = 0
    // session类型
    public var type: Int = 0
    // session对象id, 单聊时为对方id, 群聊时为群id
    public var entityId : Int64 = 0
    // session名称
    public var name: String = ""
    // note_name
    public var noteName: String? = nil
    // note_avatar
    public var noteAvatar: String? = nil
    // session remark
    public var remark: String = ""
    // 禁言标记位 2^0 全员禁言 2^1 本人禁言
    public var mute: Int = 0
    // 角色 1 成员 2 管理员 3 超级管理员 4 拥有者
    public var role: Int = 0
    // session状态
    public var status: Int
    // 未读数
    public var unreadCount: Int64 = 0
    // 草稿
    public var draft: String?
    // 最近一条消息
    public var lastMsg: String? = nil
    // 置顶时间戳
    public var topTimestamp: Int64 = 0
    // 自定义扩展数据 推荐使用json结构存储
    public var extData: String? = nil
    // 消息同步时间
    public var msgSyncTime: Int64 = 0
    // 成员同步时间
    public var memberSyncTime: Int64 = 0
    // 成员数
    public var memberCount: Int = 0
    // 功能
    public var functionFlag: Int64 = 0
    // 删除标记
    public var deleted: Int = 0
    // 消息创建时间
    public var cTime: Int64
    // 消息最近修改时间
    public var mTime: Int64
    
    public var isAutoIncrement: Bool = false // 用于定义是否使用自增的方式插入
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = Session
        public static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true)
            BindIndex(type, entityId, namedWith: "session_entity_id", isUnique: false)
            BindIndex(parentId, mTime, namedWith: "session_parent_id_m_time_idx", isUnique: false)
        }
        case id = "id"
        case parentId = "parent_id"
        case type = "type"
        case entityId = "entity_id"
        case name = "name"
        case noteName = "note_name"
        case noteAvatar = "note_avatar"
        case remark = "remark"
        case mute = "mute"
        case status = "status"
        case role = "role"
        case unreadCount = "unread_count"
        case draft = "draft"
        case lastMsg = "last_msg"
        case topTimestamp = "top_timestamp"
        case extData = "ext_data"
        case msgSyncTime = "msg_sync_time"
        case memberSyncTime = "member_sync_time"
        case memberCount = "member_count"
        case functionFlag = "function_flag"
        case deleted = "deleted"
        case cTime = "c_time"
        case mTime = "m_time"
    }
    
    public init(id: Int64) {
        self.id = id
        self.parentId = 0
        self.type = 0
        self.entityId = 0
        self.name = ""
        self.noteName = nil
        self.noteAvatar = nil
        self.remark = ""
        self.mute = 0
        self.role = 0
        self.status = 0
        self.unreadCount = 0
        self.draft = nil
        self.lastMsg = nil
        self.topTimestamp = 0
        self.extData = nil
        self.msgSyncTime = 0
        self.memberSyncTime = 0
        self.memberCount = 0
        self.functionFlag = 0
        self.deleted = 0
        self.cTime = 0
        self.mTime = 0
    }
    
    public init(id: Int64, type: Int) {
        self.id = id
        self.parentId = 0
        self.type = type
        self.entityId = 0
        self.name = ""
        self.noteName = nil
        self.noteAvatar = nil
        self.remark = ""
        self.mute = 0
        self.role = 0
        self.status = 0
        self.unreadCount = 0
        self.draft = nil
        self.lastMsg = nil
        self.topTimestamp = 0
        self.extData = nil
        self.msgSyncTime = 0
        self.memberSyncTime = 0
        self.memberCount = 0
        self.functionFlag = 0
        self.deleted = 0
        self.cTime = 0
        self.mTime = 0
    }
    
    
    public init(
        id: Int64, parentId: Int64, type: Int, entityId: Int64, name: String, noteName: String?, noteAvatar: String?,
        remark: String, mute: Int, role: Int, status: Int, unreadCount: Int64, draft: String? = nil,
        lastMsg: String? = nil, topTimestamp: Int64, extData: String? = nil, msgSyncTime: Int64, memberSyncTime: Int64,
        memberCount: Int, functionFlag: Int64, deleted: Int, cTime: Int64, mTime: Int64
    ) {
        self.id = id
        self.parentId = parentId
        self.type = type
        self.entityId = entityId
        self.name = name
        self.noteName = noteName
        self.noteAvatar = noteAvatar
        self.remark = remark
        self.mute = mute
        self.role = role
        self.status = status
        self.unreadCount = unreadCount
        self.draft = draft
        self.lastMsg = lastMsg
        self.topTimestamp = topTimestamp
        self.extData = extData
        self.msgSyncTime = msgSyncTime
        self.memberSyncTime = memberSyncTime
        self.memberCount = memberCount
        self.functionFlag = functionFlag
        self.deleted = deleted
        self.cTime = cTime
        self.mTime = mTime
    }
    
    public static func emptySession() -> Session {
        return Session(id: 0)
    }
    
    public static func emptyTypeSession(_ type: Int) -> Session {
        return Session(id: 0, type: type)
    }
    
}

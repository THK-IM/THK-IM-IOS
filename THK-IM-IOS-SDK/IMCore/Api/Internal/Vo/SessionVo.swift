//
//  SessionVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation

public class SessionVo: Codable {
    var sessionId: Int64
    var parentId: Int64?
    var type: Int
    var entityId : Int64
    var name: String
    var remark: String
    var noteName: String?
    var noteAvatar: String?
    var mute: Int
    var role: Int
    var status: Int
    var top: Int64?
    var extData: String?
    var cTime: Int64
    var mTime: Int64
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "s_id"
        case parentId = "parent_id"
        case type = "type"
        case entityId = "entity_id"
        case name = "name"
        case remark = "remark"
        case noteName = "note_name"
        case noteAvatar = "note_avatar"
        case mute = "mute"
        case role = "role"
        case status = "status"
        case top = "top"
        case extData = "ext_data"
        case cTime = "c_time"
        case mTime = "m_time"
    }
    
    public func toSession() -> Session {
        let session = Session(
            id: self.sessionId, parentId: self.parentId ?? 0, type: self.type, entityId: self.entityId, name: self.name,
            noteName: self.noteName, noteAvatar: self.noteAvatar, remark: self.remark, mute: self.mute, role: self.role,
            status: self.status, unreadCount: 0, topTimestamp: top ?? 0, extData: extData, msgSyncTime: 0,
            memberSyncTime: 0, memberCount: 0, deleted: 0, cTime: cTime, mTime: mTime
        )
        return session
    }
}

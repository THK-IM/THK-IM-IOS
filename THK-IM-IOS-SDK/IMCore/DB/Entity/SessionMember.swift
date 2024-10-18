//
//  SessionMember.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import WCDBSwift

public final class SessionMember: TableCodable {
    public var sessionId: Int64
    public var userId: Int64
    public var role: Int
    public var status: Int
    public var mute: Int
    public var noteName: String?
    public var noteAvatar: String?
    public var extData: String?
    public var deleted: Int
    public var cTime: Int64
    public var mTime: Int64

    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = SessionMember
        public static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindIndex(sessionId, userId, namedWith: "session_member_id", isUnique: true)
        }
        case sessionId = "session_id"
        case userId = "user_id"
        case role = "role"
        case status = "status"
        case mute = "mute"
        case noteName = "note_name"
        case noteAvatar = "note_avatar"
        case extData = "ext_data"
        case deleted = "deleted"
        case cTime = "c_time"
        case mTime = "m_time"
    }

    public var isAutoIncrement: Bool = false  // 用于定义是否使用自增的方式插入

    public init(
        sessionId: Int64, userId: Int64, role: Int, status: Int, mute: Int, noteName: String? = nil,
        noteAvatar: String? = nil, extData: String? = nil, deleted: Int, cTime: Int64, mTime: Int64
    ) {
        self.sessionId = sessionId
        self.userId = userId
        self.role = role
        self.status = status
        self.mute = mute
        self.noteName = noteName
        self.noteAvatar = noteAvatar
        self.extData = extData
        self.deleted = deleted
        self.cTime = cTime
        self.mTime = mTime
    }

    public init(userId: Int64) {
        self.sessionId = 0
        self.userId = userId
        self.role = 0
        self.status = 0
        self.mute = 0
        self.noteName = ""
        self.noteAvatar = ""
        self.extData = ""
        self.deleted = 0
        self.cTime = 0
        self.mTime = 0
    }
}

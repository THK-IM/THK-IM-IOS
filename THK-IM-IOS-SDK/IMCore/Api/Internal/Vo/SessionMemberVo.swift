//
//  SessionMemberVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/11.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

public class SessionMemberVo: Codable {
    public var sId: Int64
    public var uId: Int64
    public var mute: Int
    public var role: Int
    public var noteName: String?
    public var noteAvatar: String?
    public var status: Int
    public var deleted: Int
    public var cTime: Int64
    public var mTime: Int64
    
    enum CodingKeys: String, CodingKey {
        case sId = "s_id"
        case uId = "u_id"
        case role = "role"
        case status = "status"
        case mute = "mute"
        case noteName = "note_name"
        case noteAvatar = "note_avatar"
        case deleted = "deleted"
        case cTime = "c_time"
        case mTime = "m_time"
    }
    
    public init(sId: Int64, uId: Int64, mute: Int, role: Int, noteName: String? = nil, noteAvatar: String? = nil, status: Int, deleted: Int, cTime: Int64, mTime: Int64) {
        self.sId = sId
        self.uId = uId
        self.mute = mute
        self.role = role
        self.noteName = noteName
        self.noteAvatar = noteAvatar
        self.status = status
        self.deleted = deleted
        self.cTime = cTime
        self.mTime = mTime
    }
    
    public func toSessionMember() -> SessionMember {
        return SessionMember(
            sessionId: sId, userId: uId, role: role, status: status, mute: mute, noteName: noteName,
            noteAvatar: noteAvatar, extData: nil, deleted: deleted, cTime: cTime, mTime: mTime
        )
    }
}

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
        case role = "avatar"
        case status = "announce"
        case mute = "qrcode"
        case noteName = "enter_flag"
        case extData = "ext_data"
        case deleted = "deleted"
        case cTime = "c_time"
        case mTime = "m_time"
    }
    
    public var isAutoIncrement: Bool = false // 用于定义是否使用自增的方式插入
}


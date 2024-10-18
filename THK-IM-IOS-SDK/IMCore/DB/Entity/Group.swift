//
//  Group.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import WCDBSwift

public final class Group: TableCodable {
    public var id: Int64
    public var displayId: String
    public var name: String
    public var sessionId: Int64
    public var ownerId: Int64
    public var avatar: String
    public var announce: String
    public var qrcode: String
    public var enterFlag: Int
    public var memberCount: Int
    public var extData: String?
    public var cTime: Int64
    public var mTime: Int64

    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = Group
        public static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true, onConflict: .Replace)
            BindIndex(sessionId, namedWith: "group_session_idx", isUnique: false)
        }
        case id = "id"
        case displayId = "display_id"
        case name = "name"
        case sessionId = "session_id"
        case ownerId = "owner_id"
        case avatar = "avatar"
        case announce = "announce"
        case qrcode = "qrcode"
        case enterFlag = "enter_flag"
        case memberCount = "member_count"
        case extData = "ext_data"
        case cTime = "c_time"
        case mTime = "m_time"
    }

    public var isAutoIncrement: Bool = false  // 用于定义是否使用自增的方式插入

    public init(id: Int64) {
        self.id = id
        self.displayId = ""
        self.name = ""
        self.sessionId = 0
        self.ownerId = 0
        self.avatar = ""
        self.announce = ""
        self.qrcode = ""
        self.enterFlag = 0
        self.memberCount = 0
        self.extData = nil
        self.cTime = 0
        self.mTime = 0
    }

    public init(
        id: Int64, displayId: String, name: String, sessionId: Int64, ownerId: Int64,
        avatar: String, announce: String,
        qrcode: String, enterFlag: Int, memberCount: Int, extData: String?, cTime: Int64,
        mTime: Int64
    ) {
        self.id = id
        self.displayId = displayId
        self.name = name
        self.sessionId = sessionId
        self.ownerId = ownerId
        self.avatar = avatar
        self.announce = announce
        self.qrcode = qrcode
        self.enterFlag = enterFlag
        self.memberCount = memberCount
        self.extData = extData
        self.cTime = cTime
        self.mTime = mTime
    }
}

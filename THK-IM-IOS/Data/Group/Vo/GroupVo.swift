//
//  GroupVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class GroupVo: Codable {
    var id: Int64
    var displayId: String
    var ownerId: Int64
    var sessionId: Int64
    var qrcode: String
    var memberCount: Int
    var name: String
    var avatar: String
    var announce: String
    var extData: String?
    var enterFlag: Int
    var createTime: Int64
    var updateTime: Int64
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case displayId = "display_id"
        case ownerId = "owner_id"
        case sessionId = "session_id"
        case qrcode = "qrcode"
        case memberCount = "member_count"
        case name = "name"
        case avatar = "avatar"
        case announce = "announce"
        case extData = "ext_data"
        case enterFlag = "enter_flag"
        case createTime = "create_time"
        case updateTime = "update_time"
    }
    
    func toGroup() -> Group {
        return Group(
            id: id, displayId: displayId, name: name, sessionId: sessionId, ownerId: ownerId, avatar: avatar,
            announce: announce, qrcode: qrcode, enterFlag: enterFlag, memberCount: memberCount, extData: extData,
            cTime: createTime, mTime: updateTime
        )
    }
    
}

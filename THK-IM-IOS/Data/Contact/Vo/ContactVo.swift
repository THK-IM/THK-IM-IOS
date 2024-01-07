//
//  ContactVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class ContactVo: Codable {
    
    var id: Int64
    var sessionId: Int64?
    var relation: Int
    var noteName: String?
    var nickname: String
    var avatar: String
    var sex: Int
    var createTime: Int64
    var updateTime: Int64
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case sessionId = "session_id"
        case relation = "relation"
        case noteName = "note_name"
        case nickname = "nickname"
        case avatar = "avatar"
        case sex = "sex"
        case createTime = "create_time"
        case updateTime = "update_time"
    }
    
    func toContact() -> Contact {
        return Contact(
            id: id, sessionId: sessionId, noteName: noteName, relation: relation,
            extData: nil, cTime: createTime, mTime: updateTime
        )
    }
    
}

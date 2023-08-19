//
//  JoinRoomBean.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation

class JoinRoomReqBean: Codable {
    
    let roomId: String
    let uid: String
    let role: Int
    let token: String
    
    init(roomId: String, uid: String, role: Int, token: String) {
        self.roomId = roomId
        self.uid = uid
        self.role = role
        self.token = token
    }
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case uid = "uid"
        case role = "role"
        case token = "token"
    }
}

class JoinRoomResBean: Codable {
    
    let id: String
    let mode: Int
    let ownerId: String
    let createTime: Int64
    let members: Array<Member>?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case mode = "mode"
        case ownerId = "owner_id"
        case createTime = "create_time"
        case members = "participants"
    }
}

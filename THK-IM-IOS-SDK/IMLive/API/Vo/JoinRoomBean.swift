//
//  JoinRoomBean.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation

class JoinRoomReqVo: Codable {
    
    let roomId: String
    let uId: Int64
    let role: Int
    let token: String
    
    init(roomId: String, uId: Int64, role: Int, token: String) {
        self.roomId = roomId
        self.uId = uId
        self.role = role
        self.token = token
    }
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case uId = "u_id"
        case role = "role"
        case token = "token"
    }
}

class JoinRoomResVo: Codable {
    
    let id: String
    let mode: Int
    let ownerId: Int64
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

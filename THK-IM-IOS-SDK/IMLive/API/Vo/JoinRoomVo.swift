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
    
    init(roomId: String, uId: Int64, role: Int) {
        self.roomId = roomId
        self.uId = uId
        self.role = role
    }
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case uId = "u_id"
        case role = "role"
    }
}

class JoinRoomResVo: Codable {
    
    let id: String
    let mode: Int
    let members: Set<Int64>
    let ownerId: Int64
    let createTime: Int64
    let participants: Array<ParticipantVo>?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case mode = "mode"
        case ownerId = "owner_id"
        case members = "members"
        case createTime = "create_time"
        case participants = "participants"
    }
}


class RefuseJoinReqVo: Codable {
    let roomId: String
    let uId: Int64
    
    init(roomId: String, uId: Int64) {
        self.roomId = roomId
        self.uId = uId
    }
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case uId = "u_id"
    }
}

class DelRoomReqVo: Codable {
    let roomId: String
    let uId: Int64
    
    init(roomId: String, uId: Int64) {
        self.roomId = roomId
        self.uId = uId
    }
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case uId = "u_id"
    }
}

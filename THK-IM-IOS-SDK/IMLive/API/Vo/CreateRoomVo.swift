//
//  CreateRoomVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation

class CreateRoomReqVo: Codable {
    
    let uId: Int64
    let mode: Int
    
    init(uId: Int64, mode: Int) {
        self.uId = uId
        self.mode = mode
    }
    
    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case mode = "mode"
    }
}

class CreateRoomResVo: Codable {
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

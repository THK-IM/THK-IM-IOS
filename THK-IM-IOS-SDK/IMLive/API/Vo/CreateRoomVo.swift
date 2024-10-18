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
    let members: Set<Int64>

    init(uId: Int64, mode: Int, members: Set<Int64>) {
        self.uId = uId
        self.mode = mode
        self.members = members
    }

    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case mode = "mode"
        case members = "members"
    }
}

class CreateRoomResVo: Codable {
    let id: String
    let mode: Int
    let members: Set<Int64>
    let ownerId: Int64
    let createTime: Int64
    let participants: [ParticipantVo]?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case mode = "mode"
        case ownerId = "owner_id"
        case members = "members"
        case createTime = "create_time"
        case participants = "participants"
    }

    init(
        id: String, mode: Int, members: Set<Int64>, ownerId: Int64, createTime: Int64,
        participants: [ParticipantVo]?
    ) {
        self.id = id
        self.mode = mode
        self.members = members
        self.ownerId = ownerId
        self.createTime = createTime
        self.participants = participants
    }
}

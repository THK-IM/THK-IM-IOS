//
//  CreateRoomVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation

public class CreateRoomReqVo: Codable {

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

public class CreateRoomResVo: Codable {
    let id: String
    let mode: Int
    let ownerId: Int64
    let createTime: Int64
    let participants: [ParticipantVo]?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case mode = "mode"
        case ownerId = "owner_id"
        case createTime = "create_time"
        case participants = "participants"
    }

    init(
        id: String, mode: Int, ownerId: Int64, createTime: Int64,
        participants: [ParticipantVo]?
    ) {
        self.id = id
        self.mode = mode
        self.ownerId = ownerId
        self.createTime = createTime
        self.participants = participants
    }
}

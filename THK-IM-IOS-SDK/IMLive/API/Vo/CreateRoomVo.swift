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
    let mediaParams: MediaParams

    init(uId: Int64, mode: Int, mediaParams: MediaParams) {
        self.uId = uId
        self.mode = mode
        self.mediaParams = mediaParams
    }

    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case mode = "mode"
        case mediaParams = "media_params"
    }
}

public class RoomResVo: Codable {
    let id: String
    let mode: Int
    let ownerId: Int64
    let createTime: Int64
    let mediaParams: MediaParams
    let participants: [ParticipantVo]?

    enum CodingKeys: String, CodingKey {
        case id = "id"
        case mode = "mode"
        case ownerId = "owner_id"
        case createTime = "create_time"
        case mediaParams = "media_params"
        case participants = "participants"
    }

    init(
        id: String, mode: Int, ownerId: Int64, createTime: Int64, mediaParams: MediaParams,
        participants: [ParticipantVo]?
    ) {
        self.id = id
        self.mode = mode
        self.ownerId = ownerId
        self.createTime = createTime
        self.mediaParams = mediaParams
        self.participants = participants
    }
}

//
//  IMCallMsg.swift
//  THK-IM-IOS
//
//  Created by macmini on 2024/11/21.
//  Copyright © 2024 THK. All rights reserved.
//

class IMCallMsg: Codable {

    let roomId: String
    let roomOwnerId: Int64
    let roomMode: Int
    let createTime: Int64
    var accepted: Int  // 是否接听 0未接听 1被挂断 2已接通
    var acceptTime: Int64  // 接听时间
    var duration: Int64  // 通话时长

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case roomOwnerId = "room_owner_id"
        case roomMode = "room_mode"
        case createTime = "create_time"
        case accepted = "accepted"
        case acceptTime = "accept_time"
        case duration = "duration"
    }
    
    init(roomId: String, roomOwnerId: Int64, roomMode: Int, createTime: Int64, accepted: Int, acceptTime: Int64, duration: Int64) {
        self.roomId = roomId
        self.roomOwnerId = roomOwnerId
        self.roomMode = roomMode
        self.createTime = createTime
        self.accepted = accepted
        self.acceptTime = acceptTime
        self.duration = duration
    }
}

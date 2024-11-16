//
//  LeaveRoomVo.swift
//  THK-IM-IOS
//
//  Created by think on 2024/11/16.
//  Copyright © 2024 THK. All rights reserved.
//

public class LeaveRoomReqVo: Codable {

    let uId: Int64
    let roomId: String
    let msg: String

    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case roomId = "room_id"
        case msg = "msg"
    }

    init(uId: Int64, roomId: String, msg: String) {
        self.uId = uId
        self.roomId = roomId
        self.msg = msg
    }
}

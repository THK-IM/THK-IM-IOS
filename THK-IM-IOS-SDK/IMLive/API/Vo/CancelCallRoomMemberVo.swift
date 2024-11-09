//
//  CancelCallRoomMemberVo.swift
//  THK-IM-IOS
//
//  Created by think on 2024/11/9.
//  Copyright © 2024 THK. All rights reserved.
//

public class CancelCallRoomMemberReqVo: Codable {

    let uId: Int64
    let roomId: String
    let msg: String
    let members: Set<Int64>

    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case roomId = "room_id"
        case msg = "msg"
        case members = "members"
    }

    init(uId: Int64, roomId: String, msg: String, members: Set<Int64>) {
        self.uId = uId
        self.roomId = roomId
        self.msg = msg
        self.members = members
    }
}

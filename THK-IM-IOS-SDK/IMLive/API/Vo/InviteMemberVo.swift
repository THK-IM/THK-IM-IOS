//
//  InviteMemberVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/10/29.
//  Copyright © 2024 THK. All rights reserved.
//


public class InviteMemberReqVo: Codable {
    let uId: Int64
    let roomId: String
    let msg: String
    let duration: Int64
    let inviteUIds: Set<Int64>
    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case roomId = "room_id"
        case msg = "msg"
        case duration = "duration"
        case inviteUIds = "invite_u_ids"
    }
    
    init(uId: Int64, roomId: String, msg: String, duration: Int64, inviteUIds: Set<Int64>) {
        self.uId = uId
        self.roomId = roomId
        self.msg = msg
        self.duration = duration
        self.inviteUIds = inviteUIds
    }
}



//
//  KickoffMemberVo.swift
//  THK-IM-IOS
//
//  Created by macmini on 2024/10/30.
//  Copyright © 2024 THK. All rights reserved.
//

public class KickoffMemberReqVo: Codable {
    
    let uId: Int64
    let roomId: String
    let msg: String
    let kickoffUIds: Set<Int64>
    
    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case roomId = "room_id"
        case msg = "msg"
        case kickoffUIds = "kickoff_u_ids"
    }

    init(uId: Int64, roomId: String, msg: String, kickoffUIds: Set<Int64>) {
        self.uId = uId
        self.roomId = roomId
        self.msg = msg
        self.kickoffUIds = kickoffUIds
    }
}

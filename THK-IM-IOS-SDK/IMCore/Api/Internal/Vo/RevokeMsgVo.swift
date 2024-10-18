//
//  RevokeMsgVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/19.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

public class RevokeMsgVo: Codable {
    var sessionId: Int64
    var msgId: Int64
    var uId: Int64

    public init(sessionId: Int64, uId: Int64, msgId: Int64) {
        self.sessionId = sessionId
        self.uId = uId
        self.msgId = msgId
    }

    enum CodingKeys: String, CodingKey {
        case sessionId = "s_id"
        case uId = "u_id"
        case msgId = "msg_id"
    }
}

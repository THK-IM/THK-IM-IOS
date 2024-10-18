//
//  ReeditMsgVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/3/2.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

public class ReeditMsgVo: Codable {
    var sessionId: Int64
    var msgId: Int64
    var uId: Int64
    var content: String

    public init(sessionId: Int64, uId: Int64, msgId: Int64, content: String) {
        self.sessionId = sessionId
        self.uId = uId
        self.msgId = msgId
        self.content = content
    }

    enum CodingKeys: String, CodingKey {
        case sessionId = "s_id"
        case uId = "u_id"
        case msgId = "msg_id"
        case content = "content"
    }
}

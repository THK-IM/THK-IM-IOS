//
//  ApplyFriendVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class ApplyFriendVo: Codable {

    var uId: Int64
    var contactId: Int64
    var channel: Int?
    var msg: String?

    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case contactId = "contact_id"
        case channel = "channel"
        case msg = "msg"
    }

    init(uId: Int64, contactId: Int64, channel: Int?, msg: String?) {
        self.uId = uId
        self.contactId = contactId
        self.channel = channel
        self.msg = msg
    }
}

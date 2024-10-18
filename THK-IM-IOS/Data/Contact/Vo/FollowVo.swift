//
//  FollowVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class FollowVo: Codable {

    var uId: Int64
    var contactId: Int64

    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case contactId = "contact_id"
    }

    init(uId: Int64, contactId: Int64) {
        self.uId = uId
        self.contactId = contactId
    }
}

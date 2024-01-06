//
//  JoinGroupVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class JoinGroupVo: Codable {
    var groupId: Int64
    var uId: Int64
    var channel: Int
    var content: String
    
    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case uId = "u_id"
        case channel = "channel"
        case content = "content"
    }
    
}

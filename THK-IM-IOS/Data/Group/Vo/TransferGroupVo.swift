//
//  TransferGroupVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class TransferGroupVo: Codable {
    var groupId: Int64
    var uId: Int64
    var toUId: Int
    
    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case uId = "u_id"
        case toUId = "to_u_id"
    }
    
}

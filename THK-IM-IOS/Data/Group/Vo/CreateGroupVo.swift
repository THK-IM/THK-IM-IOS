//
//  CreateGroupVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class CreateGroupVo: Codable {
    var uId: Int64 = 0
    var members: Set<Int64>
    var groupName: String
    var groupAnnounce: String
    var groupType: Int // 2普通群 3超级群
    
    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case members = "members"
        case groupName = "group_name"
        case groupAnnounce = "group_announce"
        case groupType = "group_type"
    }
}

//
//  UpdateGroupVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class UpdateGroupVo: Codable {
    var groupId: Int64
    var uId: Int64
    var name: String?
    var avatar: String?
    var announce: String?
    var extData: String?
    var enterFlag: Int?

    enum CodingKeys: String, CodingKey {
        case groupId = "group_id"
        case uId = "u_id"
        case name = "name"
        case avatar = "avatar"
        case announce = "announce"
        case extData = "ext_data"
        case enterFlag = "enter_flag"
    }

}

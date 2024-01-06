//
//  UserBasicInfoVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class UserBasicInfoVo: Codable {
    var id: Int64 = 0
    var displayId: String
    var nickname: String?
    var avatar: String?
    var sex: Int?
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case displayId = "display_id"
        case nickname = "nickname"
        case avatar = "avatar"
        case sex = "sex"
    }
}

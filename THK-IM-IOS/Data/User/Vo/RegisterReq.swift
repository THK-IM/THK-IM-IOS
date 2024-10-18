//
//  RegisterReq.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class RegisterReq: Codable {
    var account: String?
    var password: String?
    var nickname: String?
    var avatar: String?
    var sex: Int?
    var birthday: Int64?

    enum CodingKeys: String, CodingKey {
        case account = "account"
        case password = "password"
        case nickname = "nickname"
        case avatar = "avatar"
        case sex = "sex"
        case birthday = "birthday"
    }
}

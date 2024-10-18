//
//  RegisterVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class RegisterVo: Codable {
    var token: String
    var user: UserVo

    enum CodingKeys: String, CodingKey {
        case token = "token"
        case user = "user"
    }

}

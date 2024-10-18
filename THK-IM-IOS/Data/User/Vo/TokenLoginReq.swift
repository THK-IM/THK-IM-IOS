//
//  TokenLoginReq.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class TokenLoginReq: Codable {
    var token: String?

    enum CodingKeys: String, CodingKey {
        case token = "token"
    }

    init(token: String? = nil) {
        self.token = token
    }
}

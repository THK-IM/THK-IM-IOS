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
    
//    public required init(from decoder: Decoder) throws {
//        let container = try decoder.container(keyedBy: CodingKeys.self)
//        self.token = try container.decode(String.self, forKey: .token)
//        self.user = try container.decode(UserVo.self, forKey: .user)
//    }
//    
//    public func encode(to encoder: Encoder) throws {
//        var container = encoder.container(keyedBy: CodingKeys.self)
//        try container.encode(token, forKey: .token)
//        try container.encode(user, forKey: .user)
//    }

}


//
//  ReviewFriendApplyVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class ReviewFriendApplyVo: Codable {

    var uId: Int64
    var applyId: Int64
    var pass: Int
    var msg: String

    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case applyId = "apply_id"
        case pass = "pass"
        case msg = "msg"
    }
}

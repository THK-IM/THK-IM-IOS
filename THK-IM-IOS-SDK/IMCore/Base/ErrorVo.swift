//
//  DeleteMsgVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/27.
//

import Foundation


class ErrorVo : Codable {
    
    var code: Int
    var message: String
    
    init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
    
    enum CodingKeys: String, CodingKey {
        case code = "code"
        case message = "message"
    }
}

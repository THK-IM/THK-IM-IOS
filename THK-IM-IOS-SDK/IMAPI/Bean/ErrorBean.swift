//
//  ErrorBean.swift
//  demo
//
//  Created by vizoss on 2023/5/21.
//

import Foundation


class ErrorBean : Codable {
    
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

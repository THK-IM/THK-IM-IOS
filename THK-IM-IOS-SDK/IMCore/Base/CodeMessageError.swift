//
//  CodeMessageError.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation

class CodeMessage : Codable {
    let code: Int
    let message: String
    
    init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
    
    enum CodingKeys: String, CodingKey {
        case code = "code"
        case message = "message"
    }
}

class CodeMessageError: NSObject, Error {
    
    private let codeMsg: CodeMessage
    
    init(codeMsg: CodeMessage) {
        self.codeMsg = codeMsg
    }
    
    override var description: String {
        return "[code:\(self.codeMsg.code), message:\(self.codeMsg.message)]"
    }
    
    override var debugDescription: String {
        return "[code:\(self.codeMsg.code), message:\(self.codeMsg.message)]"
    }
}

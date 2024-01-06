//
//  Exception.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation

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

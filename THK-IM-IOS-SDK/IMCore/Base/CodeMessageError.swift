//
//  CodeMessageError.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation

open class CodeMessageError: NSObject, Error, Codable {
    let code: Int
    let message: String
    
    init(code: Int, message: String) {
        self.code = code
        self.message = message
    }
    
    open override var description: String {
        return "[code:\(self.code), message:\(self.message)]"
    }
    
    open override var debugDescription: String {
        return "[code:\(self.code), message:\(self.message)]"
    }
    
    public static let Unknown = CodeMessageError(code: -1, message: "unknown")
}

//
//  AESPK7Coder.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/3/19.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import CryptoSwift

public class AESPK7Coder {
    
    let aes: AES
    
    public init(key: String, iv: String) throws {
        self.aes = try AES(key: key, iv: iv, padding: .pkcs5)
    }
    
    public func encrypt(text: String) throws -> String {
        let res = try self.aes.encrypt(Array(text.utf8))
        return res.toBase64()
    }
    
    public func decrypt(text: String) throws -> String? {
        if let data = Data(base64Encoded: text) {
            let byteArray: [UInt8] = Array(data)
            let res = try self.aes.decrypt(byteArray)
            return String(bytes: res, encoding: .utf8)
        } else {
            return nil
        }
    }
}

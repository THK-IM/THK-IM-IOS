//
//  CipherCrypto.swift
//  THK-IM-IOS
//
//  Created by voizoss on 2024/3/31.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class CipherCrypto: Crypto {
    var aes: AESPK7Coder?
    
    init() {
        self.aes = try? AESPK7Coder(key: "1234123412341234", iv: "0000000000000000")
    }
    
    func encrypt(_ text: String) -> String? {
        return try? aes?.encrypt(text: text)
    }
    
    func decrypt(_ cipherText: String) -> String? {
        return try? aes?.decrypt(text: cipherText)
    }
}

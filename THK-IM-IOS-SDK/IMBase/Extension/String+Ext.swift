//
//  String+Ext.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/4.
//

import Foundation
import CommonCrypto
import UIKit

extension String {
    var length: Int {
        return self.utf16.count
    }
    
    static func getNumber(count: Int) -> String? {
        if (count <= 0) {
             return nil
        } else if (count < 100) {
            return "\(count)"
        } else {
            return "99+"
        }
    }
    
    func sizeWith(_ font : UIFont , _ maxSize : CGSize) ->CGSize {
        let options = NSStringDrawingOptions.usesLineFragmentOrigin
        var attributes : [NSAttributedString.Key : Any] = [:]
        attributes[NSAttributedString.Key.font] = font
        let textBouds = self.boundingRect(
            with: maxSize,
            options: options,
            attributes: attributes,
            context: nil
        )
        return textBouds.size
    }
    
    func random(_ length: Int) -> String {
        let letters = "abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789"
        let count = UInt32(letters.count)
        var random = SystemRandomNumberGenerator()
        var randomString = ""
        for _ in 0..<length {
            let randomIndex = Int(random.next(upperBound: count))
            let randomCharacter = letters[letters.index(letters.startIndex, offsetBy: randomIndex)]
            randomString.append(randomCharacter)
        }
        return randomString
    }
    
    public var hash_256: String {
        guard let data = data(using: .utf8) else {
            return self
        }
        
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
#if swift(>=5.0)
        _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
#else
        _ = data.withUnsafeBytes { bytes in
            return CC_SHA256(bytes, CC_LONG(data.count), &digest)
        }
#endif
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

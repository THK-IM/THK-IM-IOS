//
//  String+Ext.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/4.
//

import Foundation
import CommonCrypto
import UIKit

public extension String {
    
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
    
    var sha256Hash: String {
        guard let data = data(using: .utf8) else {
            return self
        }
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA256_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return CC_SHA256(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
    
    var sha1Hash: String {
        guard let data = data(using: .utf8) else {
            return self
        }
        var digest = [UInt8](repeating: 0, count: Int(CC_SHA1_DIGEST_LENGTH))
        _ = data.withUnsafeBytes { (bytes: UnsafeRawBufferPointer) in
            return CC_SHA1(bytes.baseAddress, CC_LONG(data.count), &digest)
        }
        return digest.map { String(format: "%02x", $0) }.joined()
    }
}

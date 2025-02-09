//
//  Data+HexString.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/15.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

extension Data {

    public func hexString() -> String {
        return map { String(format: "%02x", $0) }.joined(separator: "")
    }

}

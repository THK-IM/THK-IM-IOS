//
//  Exception.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation

enum Exception: Error {
    case IMHttp(Int, String)
    case IMError(String)
}

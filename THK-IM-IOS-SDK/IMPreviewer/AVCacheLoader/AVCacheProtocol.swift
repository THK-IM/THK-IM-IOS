//
//  AVCacheProtocol.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/12.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

public protocol AVCacheProtocol: AnyObject {
    
    func maxCacheSize() -> Int64
    
    func maxCacheCount() -> Int
    
    func header(url: String) -> [String: String?]?
    
    func cacheDirPath() -> String
    
    func cacheKey(url: String) -> String
    
}


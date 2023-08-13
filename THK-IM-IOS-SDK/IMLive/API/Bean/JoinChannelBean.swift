//
//  JoinChannelBean.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/1.
//

import Foundation

class JoinChannelBean: Codable {
    
    let streamKeys: [String]
    
    enum CodingKeys: String, CodingKey {
        case streamKeys = "stream_keys"
    }
}

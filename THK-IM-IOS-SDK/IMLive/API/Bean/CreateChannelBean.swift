//
//  CreateChannelBean.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/1.
//

import Foundation

class CreateChannelBean: Codable {
    
    let id: String
    enum CodingKeys: String, CodingKey {
        case id = "id"
    }
}

//
//  UpdateNoteNameVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class UpdateNoteNameVo: Codable {
    
    var uId: Int64
    var contactId: Int64
    var noteName: String
    
    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case contactId = "contact_id"
        case noteName = "not_name"
    }
}
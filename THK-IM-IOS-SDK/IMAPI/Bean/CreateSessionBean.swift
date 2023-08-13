//
//  CreateSessionBean.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/28.
//

import Foundation

class CreateSessionBean: Codable {
    var type: Int = 0
    var entityId : Int64?
    var members: Array<Int64>
    
    init(type: Int, entityId: Int64?, members: Array<Int64>) {
        self.type = type
        self.entityId = entityId
        self.members = members
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case entityId = "entity_id"
        case members = "members"
    }
}

//
//  CreateSessionBean.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/28.
//

import Foundation

class CreateSessionBean: Codable {
    var uId: Int64 = 0
    var type: Int = 0
    var entityId : Int64
    var members: Set<Int64>?
    
    init(uId: Int64, type: Int, entityId: Int64, members: Set<Int64>?) {
        self.uId = uId
        self.type = type
        self.entityId = entityId
        self.members = members
    }
    
    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case type = "type"
        case entityId = "entity_id"
        case members = "members"
    }
}

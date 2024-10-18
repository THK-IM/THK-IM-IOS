//
//  CreateSessionVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/28.
//

import Foundation

public class CreateSessionVo: Codable {
    var uId: Int64 = 0
    var type: Int = 0
    var entityId: Int64
    var members: Set<Int64>?
    var name: String
    var remark: String

    public init(
        uId: Int64, type: Int, entityId: Int64, name: String, remark: String, members: Set<Int64>?
    ) {
        self.uId = uId
        self.type = type
        self.name = name
        self.remark = remark
        self.entityId = entityId
        self.members = members
    }

    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case type = "type"
        case name = "name"
        case remark = "remark"
        case entityId = "entity_id"
        case members = "members"
    }
}

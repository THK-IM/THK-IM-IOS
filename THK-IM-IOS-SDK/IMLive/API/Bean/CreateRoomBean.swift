//
//  CreateRoomBean.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation

class CreateRoomReqBean: Codable {
    
    let id: String
    let mode: Int
    
    init(id: String, mode: Int) {
        self.id = id
        self.mode = mode
    }
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case mode = "mode"
    }
}

class CreateRoomResBean: Codable {
    
    let id: String
    let mode: Int
    let ownerId: String
    let token: String
    let createTime: Int64
    let members: Array<Member>
    
    enum CodingKeys: String, CodingKey {
        case id = "id"
        case mode = "mode"
        case ownerId = "owner_id"
        case token = "token"
        case createTime = "create_time"
        case members = "participants"
    }
}

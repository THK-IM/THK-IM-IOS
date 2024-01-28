//
//  CreateRoomVo.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation

class CreateRoomReqVo: Codable {
    
    let uId: Int64
    let mode: Int
    
    init(uId: Int64, mode: Int) {
        self.uId = uId
        self.mode = mode
    }
    
    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case mode = "mode"
    }
}

class CreateRoomResVo: Codable {
    
    let id: String
    let mode: Int
    let ownerId: Int64
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

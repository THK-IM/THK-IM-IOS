//
//  SessionBean.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation

class SessionBean: Codable {
    var sessionId: Int64
    var type: Int
    var entityId : Int64
    var status: Int
    var top: Int64?
    var extData: String?
    var cTime: Int64
    var mTime: Int64
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case type = "type"
        case entityId = "entity_id"
        case status = "status"
        case top = "top"
        case extData = "ext_data"
        case cTime = "c_time"
        case mTime = "m_time"
    }
    
    func toSession() -> Session {
        let session = Session(
            id: self.sessionId, type: self.type, entityId: self.entityId, status: self.status,
            unreadCount: 0, topTimestamp: top, extData: extData, cTime: cTime, mTime: mTime)
        return session
    }
}

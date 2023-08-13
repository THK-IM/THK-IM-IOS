//
//  SessionBean.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation

class SessionBean: Codable {
    var sessionId: Int64 = 0
    var type: Int = 0
    var entityId : Int64 = 0
    var top: Int64? = 0
    var status: Int? = 0
    var extData: String? = nil
    var cTime: Int64 = 0
    var mTime: Int64 = 0
    
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
        let session = Session()
        session.id = self.sessionId
        session.type = self.type
        session.entityId = self.entityId
        session.status = self.status
        session.top = self.top
        session.extData = self.extData
        session.cTime = self.cTime
        session.mTime = self.mTime
        return session
    }
}

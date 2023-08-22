//
//  DeleteMsgBean.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/27.
//

import Foundation

class DeleteMsgBean: Codable {
    var sessionId: Int64 = 0
    var msgIds: Set<Int64>
    var uId: Int64 = 0
    
    init(sessionId: Int64, uId: Int64, msgIds: Set<Int64>) {
        self.sessionId = sessionId
        self.uId = uId
        self.msgIds = msgIds
    }
    
    enum CodingKeys: String, CodingKey {
        case sessionId = "session_id"
        case uId = "u_id"
        case msgIds = "msg_ids"
    }
}

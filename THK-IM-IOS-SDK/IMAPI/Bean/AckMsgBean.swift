//
//  AckMsg.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/27.
//

import Foundation

class AckMsgBean: Codable {
    var sId: Int64 = 0
    var msgIds: Set<Int64>
    var uId: Int64 = 0
    
    init(sId: Int64, uId: Int64, msgIds: Set<Int64>) {
        self.sId = sId
        self.uId = uId
        self.msgIds = msgIds
    }
    
    enum CodingKeys: String, CodingKey {
        case sId = "session_id"
        case uId = "uid"
        case msgIds = "msg_ids"
    }
}

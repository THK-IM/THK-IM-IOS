//
//  Defines.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation

public enum Role: Int {
    case Broadcaster = 1,
         Audience = 2
}

public enum Mode: Int {
    case Chat = 1,
        Audio = 2,
        Video = 3
}

public enum NotifyType: String {
    case NewStream = "NewStream",
         RemoveStream = "RemoveStream",
         DataChannelMsg = "DataChannelMsg"
}

public class NotifyBean: Codable {
    let type: String
    let message: String
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case message = "message"
    }
}

public class NewStreamNotify: Codable {
    let roomId: String
    let uid: String
    let streamKey: String
    let role: Int
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case uid = "uid"
        case streamKey = "stream_key"
        case role = "role"
    }
}

public class RemoveStreamNotify: Codable {
    let roomId: String
    let uid: String
    let streamKey: String
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case uid = "uid"
        case streamKey = "stream_key"
    }
}

public class DataChannelMsg: Codable {
    let uid: String
    let text: String
    
    init(uid: String, text: String) {
        self.uid = uid
        self.text = text
    }
    
    enum CodingKeys: String, CodingKey {
        case uid = "uid"
        case text = "text"
    }
}

public class Member: Codable {
    
    let uid: String
    let role: Int
    let joinTime: Int64
    let streamKey: String
    
    init(uid: String, role: Int, joinTime: Int64, streamKey: String) {
        self.uid = uid
        self.role = role
        self.joinTime = joinTime
        self.streamKey = streamKey
    }
    
    enum CodingKeys: String, CodingKey {
        case uid = "uid"
        case role = "role"
        case joinTime = "join_time"
        case streamKey = "stream_key"
    }
}

protocol RoomDelegate: NSObject {
    func join(_ p: BaseParticipant)
    
    func leave(_ p: BaseParticipant)
    
    func onTextMsgReceived(uId: String, text: String)
    
    func onBufferMsgReceived(data: Data)
}


class RoomObserver: NSObject {
    weak var delegate: RoomDelegate?
}

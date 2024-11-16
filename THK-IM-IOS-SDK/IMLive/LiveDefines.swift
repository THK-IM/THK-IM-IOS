//
//  LiveDefines.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation

let liveSignalEvent = "LiveSignalEvent"

public protocol LiveRequestProcessor: AnyObject {

    /**
     * 收到被呼叫请求
     */
    func onBeingRequested(signal: BeingRequestedSignal)

    /**
     * 收到取消呼叫请求
     */
    func onCancelBeingRequested(signal: CancelBeingRequestedSignal)

}

public enum LiveSignalType: Int {
    // 正在被请求通话
    case BeingRequested = 1
    // 取消被请求通话
    case CancelBeingRequested = 2
    // 拒绝请求通话
    case RejectRequest = 3
    // 接受请求通话
    case AcceptRequest = 4
    // 挂断电话
    case Hangup = 5
    // 结束通话
    case EndCall = 6
    // 踢出用户
    case KickMember = 7
}

public class LiveSignal: Codable {
    let type: Int
    let body: String

    enum CodingKeys: String, CodingKey {
        case type = "type"
        case body = "body"
    }

    func signalForType<T: Decodable>(_ type: Int, _ classOfT: T.Type) -> T? {
        if self.type == type {
            let d = self.body.data(using: .utf8) ?? Data()
            return try? JSONDecoder().decode(classOfT, from: d)
        }
        return nil
    }

}

public class BeingRequestedSignal: Codable {
    let roomId: String
    let members: Set<Int64>
    let requestId: Int64
    let mode: Int
    let msg: String
    let createTime: Int64
    let timeoutTime: Int64

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case members = "members"
        case requestId = "request_id"
        case mode = "mode"
        case msg = "msg"
        case createTime = "create_time"
        case timeoutTime = "timeout_time"
    }
    
    init(roomId: String, members: Set<Int64>, requestId: Int64, mode: Int, msg: String, createTime: Int64, timeoutTime: Int64) {
        self.roomId = roomId
        self.members = members
        self.requestId = requestId
        self.mode = mode
        self.msg = msg
        self.createTime = createTime
        self.timeoutTime = timeoutTime
    }
    
}

public class CancelBeingRequestedSignal: Codable {
    let roomId: String
    let msg: String
    let createTime: Int64
    let cancelTime: Int64

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case msg = "msg"
        case createTime = "create_time"
        case cancelTime = "cancel_time"
    }
}

public class RejectRequestSignal: Codable {
    let roomId: String
    let uId: Int64
    let msg: String
    let rejectTime: Int64

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case msg = "msg"
        case uId = "u_id"
        case rejectTime = "reject_time"
    }
}

public class AcceptRequestSignal: Codable {
    let roomId: String
    let uId: Int64
    let msg: String
    let acceptTime: Int64

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case msg = "msg"
        case uId = "u_id"
        case acceptTime = "accept_time"
    }
}

public class HangupSignal: Codable {
    let roomId: String
    let uId: Int64
    let msg: String
    let hangupTime: Int64

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case msg = "msg"
        case uId = "u_id"
        case hangupTime = "hangup_time"
    }
}

public class EndCallSignal: Codable {
    let roomId: String
    let uId: Int64
    let msg: String
    let endCallTime: Int64

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case msg = "msg"
        case uId = "u_id"
        case endCallTime = "end_call_time"
    }
}

public class KickMemberSignal: Codable {
    let roomId: String
    let uId: Int64
    let msg: String
    let kickIds: Set<Int64>
    let kickTime: Int64

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case msg = "msg"
        case uId = "u_id"
        case kickIds = "kick_ids"
        case kickTime = "kick_time"
    }
}

public enum CallType: Int {
    case RequestCalling = 1
    case BeCalling = 2
}

public enum NotifyType: String {
    case NewStream = "NewStream"
    case RemoveStream = "RemoveStream"
    case DataChannelMsg = "DataChannelMsg"
}

public enum Role: Int {
    case Broadcaster = 1
    case Audience = 2
}

public enum RoomMode: Int {
    case Chat = 1
    case Audio = 2
    case Video = 3
    case VoiceRoom = 4
    case VideoRoom = 5
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
    let uId: Int64
    let streamKey: String
    let role: Int

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case uId = "u_id"
        case streamKey = "stream_key"
        case role = "role"
    }
}

public class RemoveStreamNotify: Codable {
    let roomId: String
    let uId: Int64
    let streamKey: String

    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case uId = "u_id"
        case streamKey = "stream_key"
    }
}

public class DataChannelMsg: Codable {
    let type: Int
    let text: String

    init(type: Int, text: String) {
        self.type = type
        self.text = text
    }

    enum CodingKeys: String, CodingKey {
        case type = "type"
        case text = "text"
    }
}

public class ParticipantVo: Codable {

    let uId: Int64
    let role: Int
    let joinTime: Int64
    let streamKey: String

    init(uId: Int64, role: Int, joinTime: Int64, streamKey: String) {
        self.uId = uId
        self.role = role
        self.joinTime = joinTime
        self.streamKey = streamKey
    }

    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case role = "role"
        case joinTime = "join_time"
        case streamKey = "stream_key"
    }
}

let VolumeMsgType = 0

public class VolumeMsg: Codable {

    let uId: Int64
    let volume: Double

    enum CodingKeys: String, CodingKey {
        case uId = "u_id"
        case volume = "volume"
    }

    init(uId: Int64, volume: Double) {
        self.uId = uId
        self.volume = volume
    }

}

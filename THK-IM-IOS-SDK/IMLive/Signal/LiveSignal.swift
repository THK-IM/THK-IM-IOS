//
//  LiveSignal.swift
//  THK-IM-IOS
//
//  Created by macmini on 2024/10/29.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

public enum LiveSignalType: Int {
    // 正在被请求通话
    case BeingRequested = 1
    // 取消被请求通话
    case CancelRequested = 2
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


public class LiveSignal : Codable {
    let type: Int
    let body: String
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case body = "body"
    }
    
    func beingRequestedSignal() -> BeingRequestedSignal? {
        if self.type == LiveSignalType.BeingRequested.rawValue {
            return try? JSONDecoder().decode(BeingRequestedSignal.self, from: body.data(using: .utf8) ?? Data())
        } else {
            return nil
        }
    }
    
    func cancelRequestedSignal() -> CancelRequestedSignal? {
        if self.type == LiveSignalType.CancelRequested.rawValue {
            return try? JSONDecoder().decode(CancelRequestedSignal.self, from: body.data(using: .utf8) ?? Data())
        } else {
            return nil
        }
    }
    
    func rejectRequestSignal() -> RejectRequestSignal? {
        if self.type == LiveSignalType.RejectRequest.rawValue {
            return try? JSONDecoder().decode(RejectRequestSignal.self, from: body.data(using: .utf8) ?? Data())
        } else {
            return nil
        }
    }
    
    func acceptRequestSignal() -> AcceptRequestSignal? {
        if self.type == LiveSignalType.AcceptRequest.rawValue {
            return try? JSONDecoder().decode(AcceptRequestSignal.self, from: body.data(using: .utf8) ?? Data())
        } else {
            return nil
        }
    }
    
    func hangupSignal() -> HangupSignal? {
        if self.type == LiveSignalType.Hangup.rawValue {
            return try? JSONDecoder().decode(HangupSignal.self, from: body.data(using: .utf8) ?? Data())
        } else {
            return nil
        }
    }
    
    func endCallSignal() -> EndCallSignal? {
        if self.type == LiveSignalType.EndCall.rawValue {
            return try? JSONDecoder().decode(EndCallSignal.self, from: body.data(using: .utf8) ?? Data())
        } else {
            return nil
        }
    }
    
    func kickMemberSignal() -> KickMemberSignal? {
        if self.type == LiveSignalType.KickMember.rawValue {
            return try? JSONDecoder().decode(KickMemberSignal.self, from: body.data(using: .utf8) ?? Data())
        } else {
            return nil
        }
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
}

public class CancelRequestedSignal: Codable {
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

//
//  RoomApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation
import Moya

enum RoomApi {
    ///  创建房间
    case createRoom(_ vo: CreateRoomReqVo)
    ///  加入房间
    case joinRoom(_ vo: JoinRoomReqVo)
    ///  拒绝加入房间
    case refuseJoinRoom(_ vo: RefuseJoinReqVo)
    ///  删除房间
    case delRoom(_ vo: DelRoomReqVo)
}

extension RoomApi: TargetType {

    var baseURL: URL {
        return URL.init(string: "\(IMLiveManager.shared.liveApi.getEndpoint())/room")!
    }

    var path: String {
        switch self {
        case .createRoom:
            return ""
        case .joinRoom:
            return "/member/join"
        case .refuseJoinRoom:
            return "/member/refuse_join"
        case .delRoom:
            return ""
        }
    }

    var method: Moya.Method {
        switch self {
        case .createRoom:
            return .post
        case .joinRoom:
            return .post
        case .refuseJoinRoom:
            return .post
        case .delRoom:
            return .delete
        }
    }

    var task: Moya.Task {
        switch self {
        case let .createRoom(vo):
            return .requestJSONEncodable(vo)
        case let .joinRoom(vo):
            return .requestJSONEncodable(vo)
        case let .refuseJoinRoom(vo):
            return .requestJSONEncodable(vo)
        case let .delRoom(vo):
            return .requestJSONEncodable(vo)
        }
    }

    var validationType: Moya.ValidationType {
        return .none
    }

    var headers: [String: String]? {
        return nil
    }
}

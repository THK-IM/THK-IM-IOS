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
    ///  拨通
    case callRoomMembers(_ vo: CallRoomMemberReqVo)
    ///  取消拨通
    case cancelCallRoomMembers(_ vo: CancelCallRoomMemberReqVo)
    ///  加入房间
    case joinRoom(_ vo: JoinRoomReqVo)
    ///  邀请加入房间
    case inviteMembers(_ vo: InviteMemberReqVo)
    ///  拒绝加入房间
    case refuseJoinRoom(_ vo: RefuseJoinReqVo)
    /// 踢出用户
    case kickoffRoomMember(_ vo: KickoffMemberReqVo)
    ///  删除房间
    case delRoom(_ vo: DelRoomReqVo)
}

extension RoomApi: TargetType {

    var baseURL: URL {
        return URL.init(string: "\(RTCRoomManager.shared.liveApi.getEndpoint())/room")!
    }

    var path: String {
        switch self {
        case .createRoom:
            return ""
        case .callRoomMembers:
            return "/call"
        case .cancelCallRoomMembers:
            return "/cancel_call"
        case .joinRoom:
            return "/member/join"
        case .inviteMembers:
            return "/member/invite"
        case .refuseJoinRoom:
            return "/member/refuse_join"
        case .kickoffRoomMember:
            return "/member/kick"
        case .delRoom:
            return ""
        }
    }

    var method: Moya.Method {
        switch self {
        case .createRoom:
            return .post
        case .callRoomMembers:
            return .post
        case .cancelCallRoomMembers:
            return .post
        case .joinRoom:
            return .post
        case .inviteMembers:
            return .post
        case .refuseJoinRoom:
            return .post
        case .kickoffRoomMember:
            return .post
        case .delRoom:
            return .delete
        }
    }

    var task: Moya.Task {
        switch self {
        case let .createRoom(vo):
            return .requestJSONEncodable(vo)
        case let .callRoomMembers(vo):
            return .requestJSONEncodable(vo)
        case let .cancelCallRoomMembers(vo):
            return .requestJSONEncodable(vo)
        case let .joinRoom(vo):
            return .requestJSONEncodable(vo)
        case let .inviteMembers(vo):
            return .requestJSONEncodable(vo)
        case let .refuseJoinRoom(vo):
            return .requestJSONEncodable(vo)
        case let .kickoffRoomMember(vo):
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

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
    case createRoom(_ bean: CreateRoomReqBean)
    ///  加入房间
    case joinRoom(_ bean: JoinRoomReqBean)
}


extension RoomApi: TargetType {
    
    var baseURL: URL {
        return URL.init(string: "\(LiveManager.shared.endpoint())/room")!
    }
    
    var path: String {
        switch self {
        case .createRoom:
            return ""
        case .joinRoom:
            return "/join"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .createRoom:
            return .post
        case .joinRoom:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch self {
        case let .createRoom(bean):
            return .requestJSONEncodable(bean)
        case let .joinRoom(bean):
            return .requestJSONEncodable(bean)
        }
    }
    
    var validationType: Moya.ValidationType {
        return .none
    }
    
    var headers: [String : String]? {
        return nil
    }
}

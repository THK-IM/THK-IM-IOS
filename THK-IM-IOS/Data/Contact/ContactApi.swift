//
//  ContactApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import Moya

enum ContactApi {
    case updateNoteName(_ req: UpdateNoteNameVo)
    case reviewFriendApply(_ req: ReviewFriendApplyVo)
    case applyFriend(_ req: ApplyFriendVo)
    case black(_ req: BlackVo)
    case cancelBlack(_ req: BlackVo)
    case follow(_ req: FollowVo)
    case cancelFollow(_ req: FollowVo)
    case createContactSession(_ req: ContactSessionCreateVo)
    case queryLatestContactList(_ uId: Int64, _ mTime: Int64, _ count: Int, _ offset: Int)
}


extension ContactApi: TargetType {
    var baseURL: URL {
        return URL.init(string: "\(DataRepository.shared.getApiHost(type: "contact"))")!
    }
    
    var path: String {
        switch self {
        case .updateNoteName(_):
            return "/contact/note_name"
        case .reviewFriendApply(_):
            return "/contact/friend/apply/review"
        case .applyFriend(_):
            return "/contact/friend/apply"
        case .black(_):
            return "/contact/black"
        case .cancelBlack(_):
            return "/contact/black"
        case .follow(_):
            return "/contact/follow"
        case .cancelFollow(_):
            return "/contact/follow"
        case .createContactSession(_):
            return "/contact/session"
        case .queryLatestContactList(_, _, _, _):
            return "/contact/latest"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .updateNoteName(_):
            return .post
        case .reviewFriendApply(_):
            return .post
        case .applyFriend(_):
            return .post
        case .black(_):
            return .post
        case .cancelBlack(_):
            return .delete
        case .follow(_):
            return .post
        case .cancelFollow(_):
            return .delete
        case .createContactSession(_):
            return .post
        case .queryLatestContactList(_, _, _, _):
            return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case let .updateNoteName(req):
            return .requestJSONEncodable(req)
        case let .reviewFriendApply(req):
            return .requestJSONEncodable(req)
        case let .applyFriend(req):
            return .requestJSONEncodable(req)
        case let .black(req):
            return .requestJSONEncodable(req)
        case let .cancelBlack(req):
            return .requestJSONEncodable(req)
        case let .follow(req):
            return .requestJSONEncodable(req)
        case let .cancelFollow(req):
            return .requestJSONEncodable(req)
        case let .createContactSession(req):
            return .requestJSONEncodable(req)
        case let .queryLatestContactList(uId, mTime, count, offset):
            let urlParameters = ["u_id": uId, "m_time": mTime, "count": count, "offset": offset] as [String : Any]
            return .requestParameters(parameters: urlParameters, encoding: URLEncoding.queryString)
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
    
}

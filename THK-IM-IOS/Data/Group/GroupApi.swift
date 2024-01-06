//
//  GroupApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import Moya

enum GroupApi {
    case createGroup(_ req: CreateGroupVo)
    case searchGroup(_ displayId: String)
    case queryGroup(_ id: Int64)
    case updateGroup(_ req: UpdateGroupVo)
    case joinGroup(_ req: JoinGroupVo)
    case deleteGroup(_ req: DeleteGroupVo)
    case transferGroup(_ req: TransferGroupVo)
}

extension GroupApi: TargetType {
    var baseURL: URL {
        return URL.init(string: "\(DataRepository.shared.getApiHost(type: "group"))")!
    }
    
    var path: String {
        switch self {
        case .createGroup(_):
            return "/group"
        case .searchGroup(_):
            return "/group"
        case let .queryGroup(id):
            return "/group/\(id)"
        case let .updateGroup(req):
            return "/group/\(req.groupId)"
        case let .joinGroup(req):
            return "/group/\(req.groupId)/join"
        case let .deleteGroup(req):
            return "/group/\(req.groupId)"
        case let .transferGroup(req):
            return "/group/\(req.groupId)"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .createGroup(_):
            return .post
        case .searchGroup(_):
            return .post
        case .queryGroup(_):
            return .get
        case .updateGroup(_):
            return .put
        case .joinGroup(_):
            return .post
        case .deleteGroup(_):
            return .delete
        case .transferGroup(_):
            return .post
        }
    }
    
    var task: Moya.Task {
        switch self {
        case let .createGroup(req):
            return .requestJSONEncodable(req)
        case .searchGroup(_):
            return .requestPlain
        case .queryGroup(_):
            return .requestPlain
        case let .updateGroup(req):
            return .requestJSONEncodable(req)
        case let .joinGroup(req):
            return .requestJSONEncodable(req)
        case let .deleteGroup(req):
            return .requestJSONEncodable(req)
        case let .transferGroup(req):
            return .requestJSONEncodable(req)
        }
    }
    
    var headers: [String : String]? {
        return nil
    }
    
}


//
//  IMSessionApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/11.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

import Moya

enum IMSessionApi {
    /// 根据最近修改时间查询session成员列表
    case queryLatestSessionMembers(_ id: Int64, _ mTime: Int64, _ role: Int?, _ count: Int)
    case queryLatestSessionMessage(_ id: Int64, _ cTime: Int64, _ offset: Int, _ count: Int, _ asc: Int)
}


extension IMSessionApi: TargetType {
    
    var baseURL: URL {
        return URL.init(string: "\(IMCoreManager.shared.api.getEndpoint())")!
    }
    
    var path: String {
        switch self {
        case let .queryLatestSessionMembers(id, _, _, _):
            return "/session/\(id)/user/latest"
        case let .queryLatestSessionMessage(id, _, _, _, _):
            return "/session/\(id)/message"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .queryLatestSessionMembers(_, _, _, _):
            return .get
        case .queryLatestSessionMessage(_, _, _, _, _):
            return .get
        }
    }
    
    var task: Moya.Task {
        switch self {
        case let .queryLatestSessionMembers(_, mTime, role, count):
            var urlParameters = ["m_time": mTime, "count": count, "m_Time": mTime] as [String : Any]
            if (role != nil) {
                urlParameters["role"] = role!
            }
            return .requestParameters(parameters: urlParameters, encoding: URLEncoding.queryString)
        case let .queryLatestSessionMessage(id, cTime, offset, count, asc):
            let urlParameters = ["s_id": id, "c_time": cTime, "count": count, "offset": offset, "asc": asc] as [String : Any]
            return .requestParameters(parameters: urlParameters, encoding: URLEncoding.queryString)
        }
    }
    
    var validationType: Moya.ValidationType {
        return .none
    }
    
    var headers: [String : String]? {
        return nil
    }
}


//
//  LiveApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/2.
//

import Foundation
import Moya

enum StreamApi {
    /// 请求推流
    case requestPublish(_ bean: PublishStreamReqVo)
    /// 请求拉流
    case requestPlay(_ bean: PlayStreamReqVo)
}


extension StreamApi: TargetType {
    
    var baseURL: URL {
        return URL.init(string: "\(IMLiveManager.shared.liveApi.getEndpoint())/stream")!
    }
    
    var path: String {
        switch self {
        case .requestPublish:
            return "/publish"
        case .requestPlay:
            return "/play"
        }
    }
    
    var method: Moya.Method {
        switch self {
        case .requestPublish:
            return .post
        case .requestPlay:
            return .post
        }
    }
    
    var task: Moya.Task {
        switch self {
        case let .requestPublish(bean):
            return .requestJSONEncodable(bean)
        case let .requestPlay(bean):
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


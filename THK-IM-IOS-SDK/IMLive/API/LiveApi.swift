//
//  LiveApi.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/1.
//

import Foundation
import Moya

enum LiveApi {
    /// 请求推流
    case requestPublish(_ bean: PublishReqBean)
    /// 请求拉流
    case requestPlay(_ bean: PlayReqBean)
}


extension LiveApi: TargetType {
    
    var baseURL: URL {
        return URL.init(string: "\(LiveManager.shared.endpoint())/stream")!
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


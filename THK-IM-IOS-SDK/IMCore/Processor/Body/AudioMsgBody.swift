//
//  AudioMsgBody.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/1.
//

import Foundation

class AudioMsgBody: Codable {
    
    var duration: Int = 0
    var url: String?
    var path: String?
    
    init(duration: Int, url: String? = nil, path: String? = nil) {
        self.duration = duration
        self.url = url
        self.path = path
    }
    
    enum CodingKeys: String, CodingKey {
        case duration = "duration"
        case path = "path"
        case url = "url"
    }
}

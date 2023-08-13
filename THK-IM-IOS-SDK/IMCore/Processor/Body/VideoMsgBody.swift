//
//  VideoMsgBody.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/1.
//

import Foundation

class VideoMsgBody: Codable {
    
    var duration: Int = 0
    var width: Int = 0
    var height: Int = 0
    var thumbnailPath: String?
    var thumbnailUrl: String?
    var url: String?
    var path: String?
    
    init() {
    }
    
    init(duration: Int, width: Int, height: Int, thumbnailPath: String? = nil, thumbnailUrl: String? = nil, url: String? = nil, path: String? = nil) {
        self.duration = duration
        self.width = width
        self.height = height
        self.thumbnailPath = thumbnailPath
        self.thumbnailUrl = thumbnailUrl
        self.url = url
        self.path = path
    }
    
    enum CodingKeys: String, CodingKey {
        case duration = "duration"
        case width = "width"
        case height = "height"
        case url = "url"
        case path = "path"
        case thumbnailPath = "thumbnail_path"
        case thumbnailUrl = "thumbnail_url"
        
    }
}

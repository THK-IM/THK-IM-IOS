//
//  Media.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/25.
//

import Foundation


class Media {
    let id: String                      // 媒体id
    let type: Int                       // 1图片、2视频
    var width: Int = 0                  // 宽
    var height: Int = 0                 // 高
    var duration: Int? = nil            // 时长
    var sourcePath: String? = nil       // 本地路径
    var sourceUrl: String? = nil        // 网络URL
    var thumbPath: String? = nil        // 缩略图路径
    var thumbUrl: String?  = nil        // 缩略图URL
    
    init(id: String, type: Int) {
        self.id = id
        self.type = type
    }
}

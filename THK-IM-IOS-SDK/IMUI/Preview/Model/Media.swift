//
//  Media.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/25.
//

import Foundation


class Media {
    let id: String              // 媒体id
    let type: Int8              // 1图片、2视频
    let width: Int              // 宽
    let height: Int             // 高
    let duration: Int?          // 时长
    let sourcePath: String?     // 本地路径
    let sourceUrl: String?      // 网络URL
    let thumbPath: String?      // 缩略图路径
    let thumbUrl: String?       // 缩略图URL
    
    static func imageMedia(
        id: String,
        width: Int, height: Int,
        sourcePath: String?, sourceUrl: String?,
        thumbPath: String?, thumbUrl: String?
    ) -> Media {
        return Media(
            id: id, type: 1, duration: nil,
            width: width, height: height,
            sourcePath: sourcePath, sourceUrl: sourceUrl,
            thumbPath: thumbPath, thumbUrl: thumbUrl
        )
    }
    
    static func videoMedia(
        id: String, duration: Int,
        width: Int, height: Int,
        sourcePath: String?, sourceUrl: String?,
        thumbPath: String?, thumbUrl: String?
    ) -> Media {
        return Media(
            id: id, type: 2, duration: duration,
            width: width, height: height,
            sourcePath: sourcePath, sourceUrl: sourceUrl,
            thumbPath: thumbPath, thumbUrl: thumbUrl
        )
    }
    
    init(id: String, type: Int8, duration: Int?, width: Int, height: Int,
         sourcePath: String?, sourceUrl: String?, thumbPath: String?, thumbUrl: String?) {
        self.id = id
        self.type = type
        self.duration = duration
        self.width = width
        self.height = height
        self.sourcePath = sourcePath
        self.sourceUrl = sourceUrl
        self.thumbPath = thumbPath
        self.thumbUrl = thumbUrl
    }
}

//
//  THK-IM-IOSageMsgBody.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/10.
//

import Foundation

class ImageMsgBody: Codable {
    
    var width: Int = 0
    var height: Int = 0
    var url: String?
    var path: String?
    var shrinkUrl: String?
    var shrinkPath: String?
    
    
    
    enum CodingKeys: String, CodingKey {
        case url = "url"
        case path = "path"
        case width = "width"
        case height = "height"
        case shrinkUrl = "shrink_url"
        case shrinkPath = "shrink_path"
    }
}

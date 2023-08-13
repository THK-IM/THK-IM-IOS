//
//  MimeType.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/15.
//

import Foundation
import MobileCoreServices

open class MimeType {
    
    static let shared = MimeType()
    
    
    // 根据后缀获取对应的Mime-Type
    func mimeType(pathExtension: String) -> String {
        if let type = UTTypeCreatePreferredIdentifierForTag(kUTTagClassFilenameExtension,
                                                            pathExtension as NSString,
                                                            nil)?.takeRetainedValue() {
            if let mimeType = UTTypeCopyPreferredTagWithClass(type, kUTTagClassMIMEType)?
                .takeRetainedValue() {
                return mimeType as String
            }
        }
        
        if pathExtension.lowercased() == "oga" {
            return "audio/ogg"
        }
        
        //文件资源类型如果不知道，传万能类型application/octet-stream，服务器会自动解析文件类
        return "application/octet-stream"
    }
}

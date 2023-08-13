//
//  MediaDownloadProtocol.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/12.
//

import Foundation

protocol MediaDownloadDelegate: AnyObject {
    
    // resourceType 1 缩略图资源 2 media资源
    func onMediaDownload(_ id: String, _ resourceType: Int, _ path :String) -> Void
    
    // 需要更多的媒体 before: ture id之前的， false id之后的
    func onMoreMediaFetch(_ id: String, _ before: Bool, _ count: Int) -> [Media]
}

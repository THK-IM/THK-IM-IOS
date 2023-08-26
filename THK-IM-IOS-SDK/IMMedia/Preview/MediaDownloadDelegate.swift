//
//  MediaDownloadDelegate.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/12.
//

import Foundation

protocol MediaDownloadDelegate: AnyObject {
    
    /**
     * 媒体资源下载完成回调
     * @id 媒体资源id
     * @resourceType 1 预览资源 2 原始文件
     * @path 下载文件路径
     */
    func onMediaDownload(_ id: String, _ resourceType: Int, _ path :String) -> Void
    
    //  before: ture id之前的， false id之后的
    /**
     * 请求加载更多的媒体回调
     * @id 基准id
     * @before 基准id之前或之后
     * @count 数量
     */
    func onMoreMediaFetch(_ id: String, _ before: Bool, _ count: Int) -> [Media]
}

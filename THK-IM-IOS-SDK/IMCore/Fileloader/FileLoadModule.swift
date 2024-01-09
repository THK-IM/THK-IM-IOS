//
//  FileLoadModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/5.
//

import Foundation


public protocol FileLoadModule: AnyObject {
    
    /**
     * 下载
     * @param key 下载key, 传入网路地址或id
     * @param message 消息
     * @param listener 进度监听器
     * @return 任务id
     */
    func download(key: String, message: Message, loadListener: FileLoadListener)
    
    /**
     * 上传
     * @param path 本地路径
     * @param message 消息
     * @param listener 进度监听器
     * @return 任务id
     */
    func upload(path: String, message: Message, loadListener: FileLoadListener)
    
    
    /**
     * 取消下载
     */
    func cancelDownload(url: String)
    
    /**
     * 取消下载监听
     */
    func cancelDownloadListener(url: String, listener: FileLoadListener)
    
    /**
     * 取消上传
     */
    func cancelUpload(path: String)
    
    /**
     * 取消上传监听
     */
    func cancelUploadListener(path: String, listener: FileLoadListener)
    
    
    func reset()
    
    
}

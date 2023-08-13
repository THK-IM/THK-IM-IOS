//
//  FileLoaderModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/5.
//

import Foundation


protocol FileLoaderModule: AnyObject {
    
    /**
     *  下载
     * @param url 网路地址
     * @param path 本地路径
     * @param listener 进度监听器
     * @return 任务id
     */
    func download(url: String, path: String, loadListener: LoadListener) -> String
    
    /**
     *  上传
     * @param key 对象存储的key
     * @param path 本地路径
     * @param listener 进度监听器
     * @return 任务id
     */
    func upload(key: String, path: String, loadListener: LoadListener) -> String
    
    
    /**
     * 取消下载
     */
    func cancelDownload(taskId: String)
    
    /**
     * 取消下载监听
     */
    func cancelDownloadListener(taskId: String, listener: LoadListener)
    
    /**
     * 取消所有下载监听
     */
    func cancelAllDownloadListeners(taskId: String)
    
    /**
     * 取消上传
     */
    func cancelUpload(taskId: String)
    
    /**
     * 取消上传监听
     */
    func cancelUploadListener(taskId: String, listener: LoadListener)
    
    
    /**
     * 取消所有上传监听
     */
    func cancelAllUploadListeners(taskId: String)
    
}

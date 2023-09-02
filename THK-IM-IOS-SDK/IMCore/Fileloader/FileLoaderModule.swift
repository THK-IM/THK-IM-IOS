//
//  FileLoaderModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/5.
//

import Foundation


protocol FileLoaderModule: AnyObject {
    
    /**
     * 获取任务id
     * @param key 任务key
     * @param path 本地路径
     * @param type 类型
     * @return 任务id
     */
    func getTaskId(key: String, path: String, type: String) -> String
    
    /**
     * 获取文件上传key
     * @param sId 会话id
     * @param uId 用户id
     * @param fileName 文件名
     * @param msgClientId 客户端消息id
     * @return 任务id
     */
    func getUploadKey(
        _ sId: Int64,
        _ uId: Int64,
        _ fileName: String,
        _ msgClientId: Int64
    ) -> String
    
    /**
     *  下载
     * @param key 下载key, 传入网路地址
     * @param path 本地路径
     * @param listener 进度监听器
     * @return 任务id
     */
    func download(key: String, path: String, loadListener: FileLoaderListener) -> String
    
    /**
     *  上传
     * @param key 上传key,传入空串
     * @param path 本地路径
     * @param listener 进度监听器
     * @return 任务id
     */
    func upload(key: String, path: String, loadListener: FileLoaderListener) -> String
    
    
    /**
     * 取消下载
     */
    func cancelDownload(taskId: String)
    
    /**
     * 取消下载监听
     */
    func cancelDownloadListener(taskId: String, listener: FileLoaderListener)
    
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
    func cancelUploadListener(taskId: String, listener: FileLoaderListener)
    
    
    /**
     * 取消所有上传监听
     */
    func cancelAllUploadListeners(taskId: String)
    
}

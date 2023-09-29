//
//  StorageModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/9.
//

import Foundation


/**
  存储协议
 */
protocol StorageModule : AnyObject {
    
    // 删除文件
    func removeFile(_ fullPath: String)
    
    // 更换sandbox沙盒目录地址
    func sandboxFilePath(_ fullPath: String) -> String
    
    /**
     * 获取文件目录和文件名
     */
    func getPathsFromFullPath(_ fullPath: String) -> (String, String)
    
    
    func getFileExt(_ path: String) -> (String, String)
    
    /**
     * 从url中获取文件扩展名
     */
    func getFileExtFromUrl(_ url: String) -> String
    
    func saveMediaDataInto(_ fullPath: String, _ data: Data) throws
    
    /**
     * 拷贝文件
     */
    func copyFile(_ srcPath :String, _ dePath: String) throws
    
    /**
     * 申请存放用户头像的地址
     */
    func allocAvatarPath(_ id: Int64, _ avatarUrl: String, _ type: Int) -> String
    

    
    /**
     * 申请会话下文件存放路径，函数内不会创建文件
     * @return  ex: /{application}/{files}/im/session-${uId}/{format}/xxx.jpeg
     *          文件名重复返回 /{application}/{files}/im/session-${uId}/{format}/xxx.1.jpeg
     * @param sId 会话id
     * @param fileName 文件名 12.jpeg
     * @param format 文件类型，img(包含png/jpeg/gif等格式)/video(spx)/voice/file(包含doc/ppt/txt/等格式)
     */
    func allocSessionFilePath(
        _ sid: Int64,
        _ fileName: String,
        _ format: String
    ) -> String
    
    /**
     * 是否为IM内部的路径
     */
    func isAssignedPath(
        _ path: String,
        _ format: String,
        _ sId: Int64
    ) -> Bool
    
    /**
     * 获取session
     */
    func getSessionCacheFiles(_ format: String, _ sId: Int64) -> Array<String>
    
    /**
     * 获取session下缓存目录大小
     */
    func getSessionCacheSize(_ sId: Int64) -> Int64
}

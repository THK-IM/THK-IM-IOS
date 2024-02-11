//
//  LiveCallProtocol.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

protocol LiveCallProtocol: AnyObject {
    
    /**
     *  return 0 未知, 1 后置, 2 前置
     */
    func currentLocalCamera() -> Int
    
    /**
     * 本地摄像头是否开启 1 开启 0 关闭
     */
    func isCurrentCameraOpened()-> Bool
    
    /**
     * 切换本地摄像头
     */
    func switchLocalCamera()
    
    /**
     * 打开本地摄像头
     */
    func openLocalCamera()
    
    /**
     * 关闭本地摄像头
     */
    func closeLocalCamera()
    
    /**
     * 打开远端视频
     */
    func openRemoteVideo(user: User)
    
    /**
     * 关闭远端视频
     */
    func closeRemoteVideo(user: User)
    
    /**
     * 打开远端音频
     */
    func openRemoteAudio(user: User)
    
    /**
     * 关闭远端音频
     */
    func closeRemoteAudio(user: User)
    
    /**
     * 接听
     */
    func accept()
    
    /**
     * 挂断
     */
    func hangup()
    
}

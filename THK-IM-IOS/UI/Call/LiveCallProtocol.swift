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
     * 扬声器是否打开
     */
    func isSpeakerMuted() -> Bool

    /**
     * 打开/关闭扬声器
     */
    func muteSpeaker(mute: Bool)

    /**
     * 获取本地摄像头: 0 未知, 1 后置, 2 前置
     */
    func currentLocalCamera() -> Int

    /**
     * 切换本地摄像头
     */
    func switchLocalCamera()

    /**
     * 打开本地摄像头
     */
    func muteLocalVideo(mute: Bool)

    /**
     * 本地摄像头是否关闭
     */
    func isLocalVideoMuted() -> Bool

    /**
     * 打开/关闭本地音频
     */
    func muteLocalAudio(mute: Bool)

    /**
     * 本地音频是否关闭
     */
    func isLocalAudioMuted() -> Bool

    /**
     * 打开/关闭远端音频
     */
    func muteRemoteAudio(uId: Int64, mute: Bool)

    /**
     * 远端音频是否关闭
     */
    func isRemoteAudioMuted(uId: Int64) -> Bool

    /**
     * 打开/关闭远端视频
     */
    func muteRemoteVideo(uId: Int64, mute: Bool)

    /**
     * 远端视频是否关闭
     */
    func isRemoteVideoMuted(uId: Int64) -> Bool

    /**
     * 取消通话
     */
    func cancelCalling()

    /**
     * 接听通话
     */
    func acceptCalling()

    /**
     * 拒绝通话
     */
    func rejectCalling()

    /**
     * 挂断通话
     */
    func hangupCalling()

}

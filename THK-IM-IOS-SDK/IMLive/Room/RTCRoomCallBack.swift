//
//  RTCRoomCallBack.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/10/29.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

/// RTC事件回调
public protocol RTCRoomCallBack: NSObject {

    /**
     * RTC 用户加入
     */
    func onParticipantJoin(_ p: BaseParticipant)

    /**
     * RTC 用户离开
     */
    func onParticipantLeave(_ p: BaseParticipant)

    /**
     * RTC 文本消息
     */
    func onTextMsgReceived(_ type: Int, _ text: String)

    /**
     * RTC 数据消息
     */
    func onDataMsgReceived(_ data: Data)

    /**
     * RTC 语音音量
     */
    func onParticipantVoice(_ uId: Int64, _ volume: Double)

    /**
     * RTC 连接状态
     */
    func onConnectStatus(_ uId: Int64, _ status: Int)

    /**
     *  RTC error
     */
    func onError(_ function: String, _ err: Error)

}

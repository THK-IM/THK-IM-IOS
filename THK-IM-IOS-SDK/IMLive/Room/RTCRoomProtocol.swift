//
//  RTCRoomProtocol.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/10/29.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

/**
 * RTC协议
 */
public protocol RTCRoomProtocol: NSObject {

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
    func onTextMsgReceived(_ uId: Int64, _ text: String)

    /**
     * RTC 数据消息
     */
    func onDataMsgReceived(_ uId: Int64, _ data: Data)
    
    /**
     * RTC 语音音量
     */
    func onParticipantVoice(_ uId: Int64, _ volume: Double)
    
    
    /**
     *  RTC error
     */
    func onError(_ function: String, _ err: Error)
    
    
}


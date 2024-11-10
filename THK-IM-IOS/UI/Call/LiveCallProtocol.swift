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
     * 当前房间
     */
    func room() -> RTCRoom

    /**
     * 发起通话
     */
    func startRequestCalling()
    
    /**
     * 取消通话
     */
    func cancelRequestCalling()

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
    
    /**
     * 对方接听
     */
    func onRemoteAcceptedCallingBySignal(roomId: String, uId: Int64)

    /**
     * 对方拒绝接听
     */
    func onRemoteRejectedCallingBySignal(roomId: String, uId: Int64, msg: String)

    /**
     * 对方挂断电话
     */
    func onRemoteHangupCallingBySignal(roomId: String, uId: Int64, msg: String)

    /**
     * 被踢下
     */
    func onMemberKickedOffBySignal(roomId: String, uIds: Set<Int64>, msg: String)

    /**
     * 房间通话结束
     */
    func onCallEndedBySignal(roomId: String)

}

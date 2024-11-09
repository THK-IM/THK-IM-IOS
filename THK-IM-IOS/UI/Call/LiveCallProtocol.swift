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
    func requestCalling(mode: Mode, members: Set<Int64>)
    
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

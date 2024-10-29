//
//  LiveSignalProtocol.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/10/29.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

/**
 * 信令通知协议
 */
public protocol LiveSignalProtocol: NSObject {
    
    /**
     *  被请求呼叫
     */
    func onCallBeingRequested(_ signal: BeingRequestedSignal)
    
    /**
     *  被请求呼叫结束
     */
    func onCallCancelRequested(_ signal: CancelRequestedSignal)
    
    /**
     *  主动呼叫被拒绝
     */
    func onCallRequsetBeRejected(_ signal: RejectRequestSignal)
    
    /**
     *  主动呼叫被接受
     */
    func onCallRequsetBeAccepted(_ signal: AcceptRequestSignal)
    
    /**
     *  通话中挂断
     */
    func onCallingBeHangup(_ signal: HangupSignal)
    
    /**
     *  通话结束
     */
    func onCallingBeEnded(_ signal: EndCallSignal)
    
}


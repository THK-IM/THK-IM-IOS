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
    func onSignalReceived(_ signal: LiveSignal)
    
}


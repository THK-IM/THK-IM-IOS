//
//  IMUnSupportMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/27.
//

import Foundation

open class IMUnSupportMsgProcessor : BaseMsgProcessor {
    
    open override func messageType() -> Int {
        return MsgType.UnSupport.rawValue
    }
    
    open override func getSessionDesc(msg: Message) -> String {
        return "not support message type"
    }
}

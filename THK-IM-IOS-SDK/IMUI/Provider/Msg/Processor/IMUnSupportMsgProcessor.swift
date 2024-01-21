//
//  IMUnSupportMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/27.
//

import Foundation

open class IMUnSupportMsgProcessor : IMBaseMsgProcessor {
    
    open override func messageType() -> Int {
        return MsgType.UnSupport.rawValue
    }
    
    open override func sessionDesc(msg: Message) -> String {
        return super.sessionDesc(msg: msg) + "[未知消息]"
    }
}

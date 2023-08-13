//
//  UnSupportMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/27.
//

import Foundation

class UnSupportMsgProcessor : BaseMsgProcessor {
    
    override func messageType() -> Int {
        return MsgType.UnSupport.rawValue
    }
    
    override func getSessionDesc(msg: Message) -> String {
        return "not support message type"
    }
}

//
//  TextMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation

class TextMsgProcessor : BaseMsgProcessor {
    
    override func messageType() -> Int {
        return MsgType.TEXT.rawValue
    }
}

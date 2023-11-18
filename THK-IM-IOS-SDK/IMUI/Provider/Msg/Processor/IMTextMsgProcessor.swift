//
//  IMTextMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation

open class IMTextMsgProcessor : BaseMsgProcessor {
    
    open override func messageType() -> Int {
        return MsgType.TEXT.rawValue
    }
}

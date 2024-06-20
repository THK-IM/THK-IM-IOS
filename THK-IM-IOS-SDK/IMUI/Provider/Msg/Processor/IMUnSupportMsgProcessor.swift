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
    
    open override func msgDesc(msg: Message) -> String {
        return ResourceUtils.loadString("im_un_support_msg", comment: "")
    }
}


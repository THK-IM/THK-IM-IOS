//
//  UnSupportMsgIVProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import Foundation
import UIKit

open class IMUnSupportMsgCellProvider: IMBaseMessageCellProvider {

    open override func messageType() -> Int {
        return MsgType.UnSupport.rawValue
    }

    open override func msgBodyView(_ viewPosition: IMMsgPosType) -> any IMsgBodyView {
        let v = IMUnSupportMsgView()
        v.setViewPosition(viewPosition)
        return v
    }
    
    open override func hasBubble() -> Bool {
        return true
    }
}

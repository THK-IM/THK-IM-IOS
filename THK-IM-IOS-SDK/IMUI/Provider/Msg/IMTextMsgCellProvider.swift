//
//  IMTextMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import Foundation
import UIKit

open class IMTextMsgCellProvider: IMBaseMessageCellProvider {

    open override func messageType() -> Int {
        return MsgType.Text.rawValue
    }

    open override func hasBubble() -> Bool {
        return true
    }

    open override func msgBodyView(_ viewPosition: IMMsgPosType) -> any IMsgBodyView {
        let v = IMTextMsgView()
        v.setViewPosition(viewPosition)
        return v
    }

}

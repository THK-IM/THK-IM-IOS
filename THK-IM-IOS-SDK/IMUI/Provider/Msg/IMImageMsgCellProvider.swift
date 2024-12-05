//
//  IMImageMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/10.
//

import CocoaLumberjack
import Foundation
import UIKit

open class IMImageMsgCellProvider: IMBaseMessageCellProvider {

    open override func messageType() -> Int {
        return MsgType.Image.rawValue
    }

    open override func msgBodyView(_ viewPosition: IMMsgPosType) -> any IMsgBodyView {
        let v = IMImageMsgView()
        v.setViewPosition(viewPosition)
        return v
    }
}

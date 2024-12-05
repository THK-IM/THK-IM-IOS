//
//  IMVideoMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import CocoaLumberjack
import Foundation
import UIKit

open class IMVideoMsgCellProvider: IMBaseMessageCellProvider {

    open override func messageType() -> Int {
        return MsgType.Video.rawValue
    }

    open override func msgBodyView(_ viewPosition: IMMsgPosType) -> any IMsgBodyView {
        let v = IMVideoMsgView()
        v.setViewPosition(viewPosition)
        return v
    }

}

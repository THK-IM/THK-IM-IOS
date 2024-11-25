//
//  IMRecordMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/25.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit

public class IMRecordMsgCellProvider: IMBaseMessageCellProvider {

    override public func messageType() -> Int {
        return MsgType.Record.rawValue
    }

    open override func msgBodyView(_ viewPosition: IMMsgPosType) -> any IMsgBodyView {
        let v = IMRecordMsgView()
        v.setViewPosition(viewPosition)
        return v
    }

    open override func hasBubble() -> Bool {
        return true
    }

}

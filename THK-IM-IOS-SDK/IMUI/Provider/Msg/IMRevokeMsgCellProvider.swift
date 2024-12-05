//
//  IMRevokeMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/19.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit

public class IMRevokeMsgCellProvider: IMBaseMessageCellProvider {

    override public func messageType() -> Int {
        return MsgType.Revoke.rawValue
    }

    open override func canSelected() -> Bool {
        return true
    }

    open override func hasBubble() -> Bool {
        return true
    }

    override public func viewType(_ msg: Message) -> Int {
        return 3 * msg.type
    }

    open override func msgBodyView(_ viewPosition: IMMsgPosType) -> any IMsgBodyView {
        let v = IMRevokeMsgView()
        v.setViewPosition(viewPosition)
        return v
    }

}

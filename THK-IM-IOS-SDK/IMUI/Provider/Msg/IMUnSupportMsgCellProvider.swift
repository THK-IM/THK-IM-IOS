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

    open override func viewCellWithWrapper(_ viewType: Int, _ wrapper: IMMsgCellWrapper)
        -> IMBaseMsgCell
    {
        let identifier = self.identifier(viewType)
        return IMUnSupportMsgCell(identifier, wrapper)
    }

    open override func hasBubble() -> Bool {
        return true
    }

    open override func replyMsgView() -> IMsgBodyView {
        let view = IMUnSupportMsgView(frame: .null)
        return view
    }
}

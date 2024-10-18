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

    open override func viewCellWithWrapper(_ viewType: Int, _ wrapper: IMMsgCellWrapper)
        -> IMBaseMsgCell
    {
        let identifier = self.identifier(viewType)
        return IMImageMsgCell(identifier, wrapper)
    }

    open override func replyMsgView(
        _ msg: Message, _ session: Session?, _ delegate: IMMsgCellOperator?
    ) -> IMsgBodyView {
        let view = IMImageMsgView(frame: .null)
        view.setMessage(msg, session, delegate)
        return view
    }
}

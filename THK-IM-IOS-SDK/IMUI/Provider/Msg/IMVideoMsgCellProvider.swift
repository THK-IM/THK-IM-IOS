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

    open override func viewCellWithWrapper(_ viewType: Int, _ wrapper: IMMsgCellWrapper)
        -> IMBaseMsgCell
    {
        let identifier = self.identifier(viewType)
        return IMVideoMsgCell(identifier, wrapper)
    }

    open override func replyMsgView(
        _ msg: Message, _ session: Session?, _ delegate: IMMsgCellOperator?
    ) -> IMsgBodyView {
        let view = IMVideoMsgView(frame: .null)
        view.setMessage(msg, session, delegate)
        return view
    }

}

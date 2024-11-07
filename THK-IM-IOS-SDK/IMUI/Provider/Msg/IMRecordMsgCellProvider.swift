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

    open override func viewCellWithWrapper(_ viewType: Int, _ wrapper: IMMsgCellWrapper)
        -> IMBaseMsgCell
    {
        let identifier = self.identifier(viewType)
        return IMRecordMsgCell(identifier, wrapper)
    }

    open override func hasBubble() -> Bool {
        return true
    }

    open override func replyMsgView() -> IMsgBodyView {
        let view = IMRecordMsgView(frame: .null)
        return view
    }

}

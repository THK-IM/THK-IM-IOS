//
//  IMCallMsgProvider.swift
//  THK-IM-IOS
//
//  Created by macmini on 2024/11/21.
//  Copyright © 2024 THK. All rights reserved.
//


class IMCallMsgProvider: IMBaseMessageCellProvider {
    
    override func messageType() -> Int {
        return DemoMsgType.Call.rawValue
    }
    
    open override func viewCellWithWrapper(_ viewType: Int, _ wrapper: IMMsgCellWrapper)
        -> IMBaseMsgCell
    {
        let identifier = self.identifier(viewType)
        return IMCallMsgCell(identifier, wrapper)
    }

    open override func hasBubble() -> Bool {
        return true
    }

    open override func replyMsgView() -> IMsgBodyView {
        let view = IMCallMsgView(frame: .null)
        return view
    }

}

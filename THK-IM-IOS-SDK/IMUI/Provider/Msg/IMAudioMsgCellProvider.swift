//
//  IMAudioMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/5.
//

import Foundation
import UIKit

open class IMAudioMsgCellProvider: IMBaseMessageCellProvider {
    
    open override func messageType() -> Int {
        return MsgType.Audio.rawValue
    }
    
    open override func viewCell(_ viewType: Int, _ cellType: Int) -> BaseMsgCell {
        let msgType = self.messageType()
        let identifier = self.identifier(viewType)
        switch viewType {
        case 3 * msgType:  // 中间消息
            return IMAudioMsgCell(identifier, MiddleCellWrapper(type: cellType))
        case 3 * msgType + 2: // 自己消息
            return IMAudioMsgCell(identifier, RightCellWrapper(type: cellType))
        default: // 他人消息
            return IMAudioMsgCell(identifier, LeftCellWrapper(type: cellType))
        }
    }
    
    open override func viewSize(_ message: Message, _ session: Session?) -> CGSize {
        let maxWidth = UIScreen.main.bounds.width - 112
        return CGSize(width: maxWidth, height: 36)
    }
    
    open override func hasBubble() -> Bool {
        return true
    }
    
    open override func replyMsgView(_ msg: Message, _ session: Session?, _ delegate: IMMsgCellOperator?) -> BaseMsgView? {
        let view = IMAudioMsgView(frame:.null)
        view.setMessage(msg, session, delegate)
        return view
    }
    
    open override func replyMsgViewSize(_ message: Message, _ session: Session?) -> CGSize {
        let size = self.viewSize(message, session)
        return size
    }
    
}

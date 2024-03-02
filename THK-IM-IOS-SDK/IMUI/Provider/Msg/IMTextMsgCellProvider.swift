//
//  IMTextMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import Foundation
import UIKit

open class IMTextMsgCellProvider: IMBaseMessageCellProvider {
    
    open override func messageType() -> Int {
        return MsgType.TEXT.rawValue
    }
    
    open override func viewCell(_ viewType: Int, _ cellType: Int) -> BaseMsgCell {
        let msgType = self.messageType()
        let identifier = self.identifier(viewType)
        switch viewType {
        case 3 * msgType:  // 中间消息
            return IMTextMsgCell(identifier, MiddleCellWrapper(type: cellType))
        case 3 * msgType + 2: // 自己消息
            return IMTextMsgCell(identifier, RightCellWrapper(type: cellType))
        default: // 他人消息
            return IMTextMsgCell(identifier, LeftCellWrapper(type: cellType))
        }
    }
    
    open override func viewSize(_ message: Message, _ session: Session?) -> CGSize {
        let baseSize = super.viewSize(message, session)
        guard let content = message.content else {
            return baseSize
        }
        let maxWidth = UIScreen.main.bounds.width - 112
        let size = self.textRenderSize(content, UIFont.systemFont(ofSize: 16), maxWidth)
        return CGSize(width: size.width, height: max(size.height, 28) + 20)
    }
    
    open override func hasBubble() -> Bool {
        return true
    }
    
    open override func replyMsgView(_ msg: Message, _ session: Session?, _ delegate: IMMsgCellOperator?) -> IMsgView? {
        let view = IMTextMsgView(frame:.null)
        view.textColor = UIColor.darkGray
        view.font = UIFont.systemFont(ofSize: 12)
        view.textAlignment = .justified
        view.numberOfLines = 0
        view.setMessage(msg, session, delegate)
        return view
    }
    
    open override func replyMsgViewSize(_ message: Message, _ session: Session?) -> CGSize {
        let baseSize = super.viewSize(message, session)
        guard let content = message.content else {
            return baseSize
        }
        let maxWidth = UIScreen.main.bounds.width - 112 - 20
        let size = self.textRenderSize(content, UIFont.systemFont(ofSize: 12), maxWidth)
        return CGSize(width: size.width, height: min(size.height, 40))
    }
    
}

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
        return MsgType.Text.rawValue
    }
    
    open override func viewCell(_ viewType: Int, _ cellType: Int) -> IMBaseMsgCell {
        let msgType = self.messageType()
        let identifier = self.identifier(viewType)
        switch viewType {
        case 3 * msgType:  // 中间消息
            return IMTextMsgCell(identifier, IMMsgMiddleCellWrapper(type: cellType))
        case 3 * msgType + 2: // 自己消息
            return IMTextMsgCell(identifier, IMMsgRightCellWrapper(type: cellType))
        default: // 他人消息
            return IMTextMsgCell(identifier, IMMsgLeftCellWrapper(type: cellType))
        }
    }
    
    open override func viewSize(_ message: Message, _ session: Session?) -> CGSize {
        let baseSize = super.viewSize(message, session)
        guard let content = message.content else {
            return baseSize
        }
        let maxWidth = self.cellMaxWidth() - 24
        let updated = message.operateStatus&MsgOperateStatus.Update.rawValue > 0 ? "[已编辑]" : ""
        let size = self.textRenderSize(content + updated, UIFont.systemFont(ofSize: 16), maxWidth)
        return CGSize(width: size.width, height: max(size.height, 28) + 20)
    }
    
    open override func hasBubble() -> Bool {
        return true
    }
    
    open override func replyMsgView(_ msg: Message, _ session: Session?, _ delegate: IMMsgCellOperator?) -> IMsgBodyView? {
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
        let maxWidth = self.cellMaxWidth() - 16 - 20
        let updated = message.operateStatus&MsgOperateStatus.Update.rawValue > 0 ? "[已编辑]" : ""
        let size = self.textRenderSize(content + updated, UIFont.systemFont(ofSize: 12), maxWidth)
        return CGSize(width: size.width, height: min(size.height, 40))
    }
    
}

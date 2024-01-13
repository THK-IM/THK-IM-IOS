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
        let height = self.heightWithString(content, UIFont.boldSystemFont(ofSize: 16), maxWidth)
        return CGSize(width: baseSize.width, height: height + 16 + baseSize.height)
    }
    
}

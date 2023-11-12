//
//  IMTextMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import Foundation
import UIKit

class IMTextMsgCellProvider: IMBaseMessageCellProvider {
    
    override func messageType() -> Int {
        return MsgType.TEXT.rawValue
    }
    
    override func viewCell(_ viewType: Int, _ cellType: Int) -> BaseMsgCell {
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
    
    override func viewSize(_ message: Message) -> CGSize {
        let baseSize = super.viewSize(message)
        guard let content = message.content else {
            return baseSize
        }
        let maxWidth = UIScreen.main.bounds.width - 100
        let height = self.heightWithString(content, UIFont.boldSystemFont(ofSize: 16), maxWidth)
        return CGSize(width: baseSize.width, height: height + baseSize.height)
    }
    
    
    private func heightWithString(_ text: String, _ font: UIFont, _ maxWidth: CGFloat) -> CGFloat {
        var height: CGFloat = 0
        if text.isEmpty {
            height = 0
        } else {
            var attribute = [NSAttributedString.Key: Any]()
            attribute[.font] = font
            let retSize = (text as NSString).boundingRect(
                with: CGSize(width: maxWidth,height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attribute,
                context: nil
            ).size
            height = retSize.height
        }
        return height
    }
    
}

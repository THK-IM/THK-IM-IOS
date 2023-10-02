//
//  IMAudioMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/5.
//

import Foundation
import UIKit

class IMAudioMsgCellProvider: IMBaseMessageCellProvider {
    
    override func messageType() -> Int {
        return MsgType.Audio.rawValue
    }
    
    override func viewCell(_ viewType: Int, _ cellType: Int) -> BaseMsgCell {
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
    
    override func viewSize(_ message: Message) -> CGSize {
        let maxWidth = UIScreen.main.bounds.width - 100
        return CGSize(width: maxWidth, height: 40)
    }
    
}

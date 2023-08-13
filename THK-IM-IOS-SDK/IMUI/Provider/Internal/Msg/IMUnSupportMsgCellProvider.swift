//
//  UnSupportMsgIVProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import Foundation
import UIKit

class IMUnSupportMsgCellProvide: IMBaseMessageCellProvider {
    
    override func messageType() -> Int {
        return MsgType.UnSupport.rawValue
    }
    
    override func viewCell(_ viewType: Int, _ cellType: Int) -> BaseMsgCell {
        let msgType = self.messageType()
        let identifier = self.identifier(viewType)
        switch viewType {
        case 3 * msgType:  // 中间消息
            return UnSupportMsgCell(identifier, MiddleCellWrapper(type: cellType))
        case 3 * msgType + 2: // 自己消息
            return UnSupportMsgCell(identifier, RightCellWrapper(type: cellType))
        default: // 他人消息
            return UnSupportMsgCell(identifier, LeftCellWrapper(type: cellType))
        }
    }
    
    override func cellHeight(_ message: Message, _ sessionType: Int) -> CGFloat {
        let viewType = self.viewType(message)
        if viewType % 3 == 0 {
            return 30
        } else {
            return 30 + self.cellHeightForSessionType(sessionType)
        }
    }
    
}



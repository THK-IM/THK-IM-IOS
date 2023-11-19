//
//  UnSupportMsgIVProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import Foundation
import UIKit

open class IMUnSupportMsgCellProvide: IMBaseMessageCellProvider {
    
    open override func messageType() -> Int {
        return MsgType.UnSupport.rawValue
    }
    
    open override func viewCell(_ viewType: Int, _ cellType: Int) -> BaseMsgCell {
        let msgType = self.messageType()
        let identifier = self.identifier(viewType)
        switch viewType {
        case 3 * msgType:  // 中间消息
            return IMUnSupportMsgCell(identifier, MiddleCellWrapper(type: cellType))
        case 3 * msgType + 2: // 自己消息
            return IMUnSupportMsgCell(identifier, RightCellWrapper(type: cellType))
        default: // 他人消息
            return IMUnSupportMsgCell(identifier, LeftCellWrapper(type: cellType))
        }
    }
    
}



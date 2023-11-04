//
//  IMTimeLineMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/7.
//

import Foundation

class IMTimeLineMsgCellProvider: IMBaseMessageCellProvider {
    
    override func messageType() -> Int {
        return 9999
    }
    
    override func viewCell(_ viewType: Int, _ cellType: Int) -> BaseMsgCell {
        let msgType = self.messageType()
        let identifier = self.identifier(viewType)
        switch viewType {
        case 3 * msgType:  // 中间消息
            return IMTimeLineMsgCell(identifier, MiddleCellWrapper(type: cellType))
        case 3 * msgType + 2: // 自己消息
            return IMTimeLineMsgCell(identifier, RightCellWrapper(type: cellType))
        default: // 他人消息
            return IMTimeLineMsgCell(identifier, LeftCellWrapper(type: cellType))
        }
    }
    
    override func canSelected() -> Bool {
        return false
    }
    
}

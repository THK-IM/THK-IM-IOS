//
//  IMTimeLineMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/7.
//

import Foundation

open class IMTimeLineMsgCellProvider: IMBaseMessageCellProvider {
    
    open override func messageType() -> Int {
        return MsgType.TimeLine.rawValue
    }
    
    open override func viewCellWithWrapper(_ viewType: Int, _ wrapper: IMMsgCellWrapper) -> IMBaseMsgCell {
        let identifier = self.identifier(viewType)
        return IMTimeLineMsgCell(identifier, wrapper)
    }
    
    open override func canSelected() -> Bool {
        return false
    }
    
    
    open override func hasBubble() -> Bool {
        return false
    }
    
}

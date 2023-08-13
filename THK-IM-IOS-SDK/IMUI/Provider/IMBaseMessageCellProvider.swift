//
//  IMBaseMessageCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import Foundation
import UIKit
import CocoaLumberjack

open class IMBaseMessageCellProvider {
    
    func getSelfId() -> Int64 {
        return IMManager.shared.uId
    }
    
    open func messageType() -> Int {
        return 0
    }
    
    func viewType(_ msg: Message) -> Int {
        let msgType = self.messageType()
        let selfId = self.getSelfId()
        switch msg.fUId {
        case 0: // 中间消息
            return 3 * msgType
        case selfId: // 自己消息
            return 3 * msgType + 2
        default: // 他人消息
            return 3 * msgType + 1
        }
    }
    
    func identifier(_ viewType: Int) -> String {
        let id = "message_cell_\(viewType)"
        return id
    }
    
    /**
     @param viewType 视图类型
     @param cellType cell类型 sessionType不一样 cell有区别
     */
    open func viewCell(_ viewType: Int, _ cellType: Int) -> BaseMsgCell {
        let msgType = self.messageType()
        let identifier = self.identifier(viewType)
        switch viewType {
        case 3 * msgType:  // 中间消息
            return BaseMsgCell(identifier, MiddleCellWrapper(type: cellType))
        case 3 * msgType + 2: // 自己消息
            return BaseMsgCell(identifier, RightCellWrapper(type: cellType))
        default: // 他人消息
            return BaseMsgCell(identifier, LeftCellWrapper(type: cellType))
        }
    }
    
    open func cellHeight(_ message: Message, _ sessionType: Int) -> CGFloat {
        return 48.0 + self.cellHeightForSessionType(sessionType)
    }
    
    open func cellHeightForSessionType(_ sessionType: Int) -> CGFloat {
        if sessionType == SessionType.Group.rawValue {
            return 20.0
        } else {
            return 0
        }
    }
    
}

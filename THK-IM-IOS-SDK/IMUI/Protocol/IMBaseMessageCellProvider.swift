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
    
    open func getSelfId() -> Int64 {
        return IMCoreManager.shared.uId
    }
    
    open func messageType() -> Int {
        return 0
    }
    
    open func viewType(_ msg: Message) -> Int {
        let msgType = self.messageType()
        let selfId = self.getSelfId()
        switch msg.fromUId {
        case 0: // 中间消息
            return 3 * msgType
        case selfId: // 自己消息
            return 3 * msgType + 2
        default: // 他人消息
            return 3 * msgType + 1
        }
    }
    
    open func identifier(_ viewType: Int) -> String {
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
    
    open func viewSize(_ message: Message, _ session: Session?) -> CGSize {
        return CGSize(width: 100.0, height: 20.0)
    }
    
    open func cellHeightForSessionType(_ sessionType: Int) -> CGFloat {
        if sessionType == SessionType.Group.rawValue {
            return 20.0
        } else {
            return 0
        }
    }
    
    open func canSelected() -> Bool {
        return true
    }
    
    open func heightWithString(_ text: String, _ font: UIFont, _ maxWidth: CGFloat) -> CGFloat {
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

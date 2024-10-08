//
//  IMRevokeMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/19.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit

public class IMRevokeMsgCellProvider: IMBaseMessageCellProvider {
    
    override public func messageType() -> Int {
        return MsgType.Revoke.rawValue
    }
    
    override public func viewType(_ msg: Message) -> Int {
        return 3 * msg.type
    }
    
    override public func viewCell(_ viewType: Int, _ cellType: Int) -> IMBaseMsgCell {
        let msgType = self.messageType()
        let identifier = self.identifier(viewType)
        switch viewType {
        case 3 * msgType:  // 中间消息
            return IMRevokeMsgCell(identifier, IMMsgMiddleCellWrapper(type: cellType))
        case 3 * msgType + 2: // 自己消息
            return IMRevokeMsgCell(identifier, IMMsgRightCellWrapper(type: cellType))
        default: // 他人消息
            return IMRevokeMsgCell(identifier, IMMsgLeftCellWrapper(type: cellType))
        }
    }
    
    public override func viewSize(_ message: Message, _ session: Session?) -> CGSize {
        return CGSize(width: self.cellMaxWidth(), height: 40.0)
    }
    
    open override func canSelected() -> Bool {
        return true
    }
    
    open override func hasBubble() -> Bool {
        return true
    }
    
}

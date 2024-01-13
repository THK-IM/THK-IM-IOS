//
//  IMRecordMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/25.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit

public class IMRecordMsgCellProvider: IMBaseMessageCellProvider {
    
    override public func messageType() -> Int {
        return MsgType.Record.rawValue
    }
    
    open override func viewCell(_ viewType: Int, _ cellType: Int) -> BaseMsgCell {
        let msgType = self.messageType()
        let identifier = self.identifier(viewType)
        switch viewType {
        case 3 * msgType:  // 中间消息
            return IMRecordMsgCell(identifier, MiddleCellWrapper(type: cellType))
        case 3 * msgType + 2: // 自己消息
            return IMRecordMsgCell(identifier, RightCellWrapper(type: cellType))
        default: // 他人消息
            return IMRecordMsgCell(identifier, LeftCellWrapper(type: cellType))
        }
    }
    
    open override func viewSize(_ message: Message, _ session: Session?) -> CGSize {
        guard let content = message.content else {
            return super.viewSize(message, session)
        }
        guard let recordBody = try? JSONDecoder().decode(IMRecordMsgBody.self, from: content.data(using: .utf8) ?? Data()) else {
            return super.viewSize(message, session)
        }
        let maxWidth = UIScreen.main.bounds.width - 112
        let height = self.heightWithString(recordBody.content, UIFont.boldSystemFont(ofSize: 12), maxWidth)
        return CGSize(width: maxWidth, height: height + 61)
        
    }
    
}

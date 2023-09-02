//
//  IMImageMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/10.
//

import Foundation
import UIKit
import CocoaLumberjack

class IMImageMsgCellProvider: IMBaseMessageCellProvider {
    
    override func messageType() -> Int {
        return MsgType.IMAGE.rawValue
    }
    
    override func viewCell(_ viewType: Int, _ cellType: Int) -> BaseMsgCell {
        let msgType = self.messageType()
        let identifier = self.identifier(viewType)
        switch viewType {
        case 3 * msgType:  // 中间消息
            return IMImageMsgCell(identifier, MiddleCellWrapper(type: cellType))
        case 3 * msgType + 2: // 自己消息
            return IMImageMsgCell(identifier, RightCellWrapper(type: cellType))
        default: // 他人消息
            return IMImageMsgCell(identifier, LeftCellWrapper(type: cellType))
        }
    }
    
    override func cellHeight(_ message: Message, _ sessionType: Int) -> CGFloat {
//        do {
//            let imageBody = try JSONDecoder().decode(
//                ImageMsgBody.self,
//                from: message.content.data(using: .utf8) ?? Data())
//            var calHeight = 20
//            if (imageBody.width >= imageBody.height) {
//                var calWidth = min(200, imageBody.width)
//                calWidth = max(80, calWidth)
//                calHeight += max(80, calWidth * imageBody.height / imageBody.width)
//            } else if (imageBody.height > imageBody.width) {
//                var height = min(200, imageBody.height)
//                calHeight += max(80, height)
//            }
//            return CGFloat(calHeight) + self.cellHeightForSessionType(sessionType)
//        } catch {
//            DDLogError(error)
//        }
        return super.cellHeight(message, sessionType)
    }
    
}

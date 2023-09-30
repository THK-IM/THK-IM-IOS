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
    
    override func viewSize(_ message: Message) -> CGSize {
        var width = 100
        var height = 100
        do {
            if (message.content != nil) {
                let imageBody = try JSONDecoder().decode(
                    IMImageMsgBody.self,
                    from: message.content!.data(using: .utf8) ?? Data())
                if imageBody.height != nil && imageBody.width != nil {
                    width = imageBody.width!
                    height = imageBody.height!
                }
            } else if (message.data != nil) {
                let imageData = try JSONDecoder().decode(
                    IMImageMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data())
                if imageData.height != nil && imageData.width != nil {
                    width = imageData.width!
                    height = imageData.height!
                }
            }
            if (width >= height) {
                let calWidth = max(80, min(200, width))
                let calHeight = max(80, calWidth * height / width)
                return CGSize(width: calWidth, height: calHeight)
            } else if (height > width) {
                let calHeight = max(80, min(200, height))
                let calWidth = max(80, calHeight * width / height)
                return CGSize(width: calWidth, height: calHeight)
            }
        } catch {
            DDLogError(error)
        }
        return super.viewSize(message)
    }
    
}

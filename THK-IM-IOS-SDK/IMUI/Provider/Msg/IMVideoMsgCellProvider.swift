//
//  IMVodieMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit
import CocoaLumberjack

class IMVideoMsgCellProvider: IMBaseMessageCellProvider {
    
    override func messageType() -> Int {
        return MsgType.VIDEO.rawValue
    }
    
    override func viewCell(_ viewType: Int, _ cellType: Int) -> BaseMsgCell {
        let msgType = self.messageType()
        let identifier = self.identifier(viewType)
        switch viewType {
        case 3 * msgType:  // 中间消息
            return IMVideoMsgCell(identifier, MiddleCellWrapper(type: cellType))
        case 3 * msgType + 2: // 自己消息
            return IMVideoMsgCell(identifier, RightCellWrapper(type: cellType))
        default: // 他人消息
            return IMVideoMsgCell(identifier, LeftCellWrapper(type: cellType))
        }
    }
    
    override func viewSize(_ message: Message) -> CGSize {
        var width = 100.0
        var height = 100.0
        do {
            if (message.data != nil) {
                let data = try JSONDecoder().decode(
                    IMVideoMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data())
                if data.height != nil && data.width != nil {
                    width = Double(data.width!).ptValue()
                    height = Double(data.height!).ptValue()
                }
            }
            if (message.content != nil) {
                let body = try JSONDecoder().decode(
                    IMVideoMsgBody.self,
                    from: message.content!.data(using: .utf8) ?? Data())
                if body.height != nil && body.width != nil {
                    width = Double(body.width!).ptValue()
                    height = Double(body.height!).ptValue()
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

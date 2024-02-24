//
//  IMVideoMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import Foundation
import UIKit
import CocoaLumberjack

open class IMVideoMsgCellProvider: IMBaseMessageCellProvider {
    
    open override func messageType() -> Int {
        return MsgType.VIDEO.rawValue
    }
    
    open override func viewCell(_ viewType: Int, _ cellType: Int) -> BaseMsgCell {
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
    
    open override func viewSize(_ message: Message, _ session: Session?) -> CGSize {
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
            } else  {
                let calHeight = max(80, min(200, height))
                let calWidth = max(80, calHeight * width / height)
                return CGSize(width: calWidth, height: calHeight)
            }
        } catch {
            DDLogError("\(error)")
            return super.viewSize(message, session)
        }
    }
    
    open override func replyMsgView(_ msg: Message, _ session: Session?, _ delegate: IMMsgCellOperator?) -> BaseMsgView? {
        let view = IMVideoMsgView(frame:.null)
        view.setMessage(msg, session, delegate)
        return view
    }
    
    open override func replyMsgViewSize(_ message: Message, _ session: Session?) -> CGSize {
        let size = self.viewSize(message, session)
        return CGSize(width: size.width * 0.25, height: size.height * 0.25)
    }
    
}


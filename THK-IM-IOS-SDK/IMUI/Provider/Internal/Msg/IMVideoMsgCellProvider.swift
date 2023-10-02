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
    
//    override func cellHeight(_ message: Message, _ sessionType: Int) -> CGFloat {
////        do {
////            let videoBody = try JSONDecoder().decode(
////                VideoMsgBody.self,
////                from: message.content.data(using: .utf8) ?? Data())
////            var calHeight = 20
////            if (videoBody.width >= videoBody.height) {
////                var calWidth = min(160, videoBody.width)
////                calWidth = max(100, calWidth)
////                calHeight += max(100, calWidth * videoBody.height / videoBody.width)
////            } else if (videoBody.height > videoBody.width) {
////                var height = min(160, videoBody.height)
////                calHeight += max(100, height)
////            }
////            return CGFloat(calHeight) + self.cellHeightForSessionType(sessionType)
////        } catch {
////            DDLogError(error)
////        }
//        return super.cellHeight(message, sessionType)
//    }
    
    override func viewSize(_ message: Message) -> CGSize {
        var width = 100
        var height = 100
        do {
            if (message.content != nil) {
                let body = try JSONDecoder().decode(
                    IMVideoMsgBody.self,
                    from: message.content!.data(using: .utf8) ?? Data())
                if body.height != nil && body.width != nil {
                    width = body.width!
                    height = body.height!
                }
            } else if (message.data != nil) {
                let data = try JSONDecoder().decode(
                    IMVideoMsgData.self,
                    from: message.data!.data(using: .utf8) ?? Data())
                if data.height != nil && data.width != nil {
                    width = data.width!
                    height = data.height!
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


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
    
    open override func viewCell(_ viewType: Int, _ cellType: Int) -> IMBaseMsgCell {
        let msgType = self.messageType()
        let identifier = self.identifier(viewType)
        switch viewType {
        case 3 * msgType:  // 中间消息
            return IMRecordMsgCell(identifier, IMMsgMiddleCellWrapper(type: cellType))
        case 3 * msgType + 2: // 自己消息
            return IMRecordMsgCell(identifier, IMMsgRightCellWrapper(type: cellType))
        default: // 他人消息
            return IMRecordMsgCell(identifier, IMMsgLeftCellWrapper(type: cellType))
        }
    }
    
    open override func viewSize(_ message: Message, _ session: Session?) -> CGSize {
        guard let content = message.content else {
            return super.viewSize(message, session)
        }
        guard let recordBody = try? JSONDecoder().decode(IMRecordMsgBody.self, from: content.data(using: .utf8) ?? Data()) else {
            return super.viewSize(message, session)
        }
        let maxWidth = self.cellMaxWidth() - 24
        let size = self.textRenderSize(recordBody.content, UIFont.systemFont(ofSize: 12), maxWidth)
        return CGSize(width: max(size.width + 20, 120), height: size.height + 28 + 20)
    }
    
    open override func hasBubble() -> Bool {
        return true
    }
    
    open override func replyMsgView(_ msg: Message, _ session: Session?, _ delegate: IMMsgCellOperator?) -> IMsgBodyView? {
        let view = IMRecordMsgView(frame:.null)
        view.setMessage(msg, session, delegate)
        return view
    }
    
    open override func replyMsgViewSize(_ message: Message, _ session: Session?) -> CGSize {
        guard let content = message.content else {
            return super.viewSize(message, session)
        }
        guard let recordBody = try? JSONDecoder().decode(IMRecordMsgBody.self, from: content.data(using: .utf8) ?? Data()) else {
            return super.viewSize(message, session)
        }
        let maxWidth = self.cellMaxWidth() - 24 - 20
        let size = self.textRenderSize(recordBody.content, UIFont.systemFont(ofSize: 12), maxWidth)
        return CGSize(width: max(size.width + 20, 120), height: size.height + 28 + 20)
    }
    
    public override func msgTopForSession(_ message: Message, _ session: Session?) -> CGFloat {
        return super.msgTopForSession(message, session) + 10
    }
    
}

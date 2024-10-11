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
    
    public init() {
        
    }
    
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
    open func viewCell(_ viewType: Int, _ cellType: Int) -> IMBaseMsgCell {
        let msgType = self.messageType()
        let identifier = self.identifier(viewType)
        switch viewType {
        case 3 * msgType:  // 中间消息
            return IMBaseMsgCell(identifier, IMMsgMiddleCellWrapper(type: cellType))
        case 3 * msgType + 2: // 自己消息
            return IMBaseMsgCell(identifier, IMMsgRightCellWrapper(type: cellType))
        default: // 他人消息
            return IMBaseMsgCell(identifier, IMMsgLeftCellWrapper(type: cellType))
        }
    }
    
    open func viewSize(_ message: Message, _ session: Session?) -> CGSize {
        return CGSize(width: 100.0, height: 48.0)
    }
    
    open func cellMaxWidth() -> CGFloat {
        return UIScreen.main.bounds.width - IMUIManager.shared.msgCellAvatarLeft - IMUIManager.shared.msgCellAvatarWidth 
        - IMUIManager.shared.msgCellAvatarRight - IMUIManager.shared.msgCellPadding
    }
    
    open func canSelected() -> Bool {
        return true
    }
    
    open func textRenderSize(_ text: String, _ font: UIFont, _ maxWidth: CGFloat) -> CGSize {
        if text.isEmpty {
            return CGSize(width: 0, height: font.pointSize)
        } else {
            var attribute = [NSAttributedString.Key: Any]()
            attribute[.font] = font
            let retSize = (text as NSString).boundingRect(
                with: CGSize(width: maxWidth,height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attribute,
                context: nil
            ).size
            return retSize
        }
    }
    
    open func replyMsgView(_ msg: Message, _ session: Session?, _ delegate: IMMsgCellOperator?) -> IMsgBodyView {
        let view = IMTextMsgView()
        view.textColor = UIColor.darkGray
        view.font = UIFont.systemFont(ofSize: 12)
        view.numberOfLines = 0
        return view
    }
    
    open func replyMsgViewSize(_ message: Message, _ session: Session?) -> CGSize {
        return self.viewSize(message, session)
    }
    
    open func msgTopForSession(_ message: Message, _ session: Session?) -> CGFloat {
        if message.fromUId > 0 {
            var top:CGFloat = 20
            if session?.type != SessionType.Single.rawValue {
                top += 24
            }
            return top
        } else {
            return 10
        }
    }
    
    open func hasBubble() -> Bool {
        return false
    }
    
}

//
//  IMBaseMessageCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import CocoaLumberjack
import Foundation
import UIKit

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
        case 0:  // 中间消息
            return 3 * msgType
        case selfId:  // 自己消息
            return 3 * msgType + 2
        default:  // 他人消息
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
        switch viewType {
        case 3 * msgType:  // 中间消息
            return viewCellWithWrapper(viewType, IMMsgMiddleCellWrapper(type: cellType))
        case 3 * msgType + 2:  // 自己消息
            return viewCellWithWrapper(viewType, IMMsgRightCellWrapper(type: cellType))
        default:  // 他人消息
            return viewCellWithWrapper(viewType, IMMsgLeftCellWrapper(type: cellType))
        }
    }

    open func viewCellWithWrapper(_ viewType: Int, _ wrapper: IMMsgCellWrapper) -> IMBaseMsgCell {
        let identifier = self.identifier(viewType)
        return IMBaseMsgCell(identifier, wrapper)
    }

    open func cellMaxWidth() -> CGFloat {
        return UIScreen.main.bounds.width - IMUIManager.shared.msgCellAvatarLeft
            - IMUIManager.shared.msgCellAvatarWidth
            - IMUIManager.shared.msgCellAvatarRight - 24.0 - IMUIManager.shared.msgCellPadding
    }

    open func canSelected() -> Bool {
        return true
    }

    open func hasBubble() -> Bool {
        return false
    }

    open func textRenderSize(_ text: String, _ font: UIFont, _ maxWidth: CGFloat) -> CGSize {
        if text.isEmpty {
            return CGSize(width: 0, height: font.pointSize)
        } else {
            var attribute = [NSAttributedString.Key: Any]()
            attribute[.font] = font
            let retSize = (text as NSString).boundingRect(
                with: CGSize(width: maxWidth, height: CGFloat.greatestFiniteMagnitude),
                options: [.usesLineFragmentOrigin, .usesFontLeading],
                attributes: attribute,
                context: nil
            ).size
            return retSize
        }
    }

    open func replyMsgView(_ msg: Message, _ session: Session?, _ delegate: IMMsgCellOperator?)
        -> IMsgBodyView
    {
        let view = IMTextMsgView()
        view.textColor = UIColor.darkGray
        view.font = UIFont.systemFont(ofSize: 12)
        view.numberOfLines = 0
        return view
    }

}

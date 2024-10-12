//
//  IMTextMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import Foundation
import UIKit

open class IMTextMsgCellProvider: IMBaseMessageCellProvider {
    
    open override func messageType() -> Int {
        return MsgType.Text.rawValue
    }
    
    open override func viewCellWithWrapper(_ viewType: Int, _ wrapper: IMMsgCellWrapper) -> IMBaseMsgCell {
        let identifier = self.identifier(viewType)
        return IMTextMsgCell(identifier, wrapper)
    }
    
    open override func hasBubble() -> Bool {
        return true
    }
    
    open override func replyMsgView(_ msg: Message, _ session: Session?, _ delegate: IMMsgCellOperator?) -> IMsgBodyView {
        let view = IMTextMsgView(frame:.null)
        view.textColor = UIColor.darkGray
        view.font = UIFont.systemFont(ofSize: 12)
        view.textAlignment = .left
        view.numberOfLines = 0
        view.setMessage(msg, session, delegate)
        return view
    }
    
}

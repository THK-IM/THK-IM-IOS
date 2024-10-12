//
//  IMAudioMsgCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/5.
//

import Foundation
import UIKit

open class IMAudioMsgCellProvider: IMBaseMessageCellProvider {
    
    open override func messageType() -> Int {
        return MsgType.Audio.rawValue
    }
    
    open override func viewCellWithWrapper(_ viewType: Int, _ wrapper: IMMsgCellWrapper) -> IMBaseMsgCell {
        let identifier = self.identifier(viewType)
        return IMAudioMsgCell(identifier, wrapper)
    }
    
    open override func hasBubble() -> Bool {
        return true
    }
    
    open override func replyMsgView(_ msg: Message, _ session: Session?, _ delegate: IMMsgCellOperator?) -> IMsgBodyView {
        let view = IMAudioMsgView(frame:.null)
        view.setMessage(msg, session, delegate)
        return view
    }
    
    
}

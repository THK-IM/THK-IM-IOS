//
//  IMImageCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/10.
//

import Foundation
import UIKit
import CocoaLumberjack
import Kingfisher

class IMImageMsgCell: BaseMsgCell {
    
    private let view = IMImageMsgView(frame: .null)
    
    open override func msgView() -> UIView {
        return self.view
    }
    
    open override func setMessage(_ position: Int, _ messages: Array<Message>, _ session: Session, _ delegate: IMMsgCellOperator) {
        super.setMessage(position, messages, session, delegate)
        guard let msg = self.message else {
            return
        }
        self.view.setMessage(msg, session, delegate)
    }
    
}

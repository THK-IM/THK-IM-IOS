//
//  IMRecordMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/25.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit

class IMRecordMsgCell: BaseMsgCell {
    
    private lazy var view: IMRecordMsgView = {
        let view = IMRecordMsgView()
        return view
    }()
    
    open override func msgView() -> IMsgView {
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


//
//  IMRevokeMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/19.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit
import CocoaLumberjack
import RxGesture

class IMRevokeMsgCell: BaseMsgCell {
    
    private lazy var view: IMRevokeMsgView = {
        let view = IMRevokeMsgView()
        return view
    }()
    
    
    override func msgView() -> UIView {
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

//
//  IMTextMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import UIKit
import CocoaLumberjack
import RxSwift

class IMTextMsgCell: BaseMsgCell {
    
    private lazy var view: IMTextMsgView = {
        let view = IMTextMsgView()
        view.textColor = UIColor.black
        if self.cellPosition() == IMMsgPosType.Mid.rawValue {
            view.textAlignment = .center
        } else {
            view.textAlignment = .left
        }
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
        self.view.setMessage(msg, session)
    }
    
}

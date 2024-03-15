//
//  IMTextMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import UIKit
import CocoaLumberjack
import RxSwift

class IMTextMsgCell: IMBaseMsgCell {
    
    private let fontSize:CGFloat = 16
    
    private lazy var view: IMTextMsgView = {
        let view = IMTextMsgView()
        view.numberOfLines = 0
        view.font = UIFont.systemFont(ofSize: fontSize)
        view.padding = UIEdgeInsets.init(top: 4, left: 8, bottom: 4, right: 8)
        if self.cellPosition() == IMMsgPosType.Mid.rawValue {
            view.textAlignment = .left
            view.textColor = UIColor.white
        } else {
            view.textAlignment = .left
            view.textColor = UIColor.black
        }
        return view
    }()
    
    open override func msgView() -> IMsgBodyView {
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

//
//  IMUnSupportMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import Foundation
import UIKit

class IMUnSupportMsgCell: BaseMsgCell {
    
    private lazy var view: IMUnSupportMsgView = {
        let view = IMUnSupportMsgView()
        if self.cellPosition() == IMMsgPosType.Mid.rawValue {
            view.textColor = UIColor.white
            view.textAlignment = .center
        } else {
            view.textColor = UIColor.black
            view.textAlignment = .left
        }
        return view
    }()
    
    override func msgView() -> UIView {
        return self.view.contentView()
    }
    
    open override func setMessage(_ position: Int, _ messages: Array<Message>, _ session: Session, _ delegate: IMMsgCellOperator) {
        super.setMessage(position, messages, session, delegate)
        guard let msg = self.message else {
            return
        }
        self.view.setMessage(msg, session, delegate)
    }
}

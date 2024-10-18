//
//  IMUnSupportMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import Foundation
import UIKit

class IMUnSupportMsgCell: IMBaseMsgCell {

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

    open override func msgView() -> IMsgBodyView {
        return self.view
    }

    open override func setMessage(
        _ position: Int, _ messages: [Message], _ session: Session, _ delegate: IMMsgCellOperator
    ) {
        super.setMessage(position, messages, session, delegate)
        guard let msg = self.message else {
            return
        }
        self.view.setMessage(msg, session, delegate)
    }
}

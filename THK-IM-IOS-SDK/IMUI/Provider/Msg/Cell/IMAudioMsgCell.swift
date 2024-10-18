//
//  IMAudioMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/5.
//

import CocoaLumberjack
import Kingfisher
import UIKit

class IMAudioMsgCell: IMBaseMsgCell {

    private lazy var view: IMAudioMsgView = {
        let view = IMAudioMsgView()
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

    open override func onMessageShow() {
        // 语音消息 点击之后才显示已读
    }

}

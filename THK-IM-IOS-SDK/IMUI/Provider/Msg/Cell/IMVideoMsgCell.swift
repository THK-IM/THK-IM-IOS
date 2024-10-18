//
//  IMVideoMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/10.
//

import CocoaLumberjack
import Foundation
import Kingfisher
import UIKit

open class IMVideoMsgCell: IMBaseMsgCell {

    private let view = IMVideoMsgView(frame: .null)

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

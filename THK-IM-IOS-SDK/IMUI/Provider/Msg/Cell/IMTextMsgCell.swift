//
//  IMTextMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import CocoaLumberjack
import RxSwift
import UIKit

class IMTextMsgCell: IMBaseMsgCell {

    private let fontSize: CGFloat = 16

    private lazy var view: IMTextMsgView = {
        let view = IMTextMsgView()
        view.numberOfLines = 0
        view.padding = UIEdgeInsets.init(top: 4, left: 8, bottom: 4, right: 8)
        if self.cellPosition() == IMMsgPosType.Mid.rawValue {
            view.textAlignment = .left
            view.textColor = UIColor.white
            view.font = UIFont.systemFont(ofSize: fontSize - 4)
        } else {
            view.font = UIFont.systemFont(ofSize: fontSize)
            view.textAlignment = .left
            view.textColor = UIColor.init(hex: "0A0E10")
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

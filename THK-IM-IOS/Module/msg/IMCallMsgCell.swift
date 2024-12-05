//
//  IMCallMsgCell.swift
//  THK-IM-IOS
//
//  Created by macmini on 2024/11/21.
//  Copyright © 2024 THK. All rights reserved.
//

//class IMCallMsgCell: IMBaseMsgCell {
//
//    private lazy var view: IMCallMsgView = {
//        let view = IMCallMsgView()
//        return view
//    }()
//
//    open override func msgView() -> IMsgBodyView {
//        return self.view
//    }
//
//    open override func setMessage(
//        _ position: Int, _ messages: [Message], _ session: Session, _ delegate: IMMsgCellOperator
//    ) {
//        super.setMessage(position, messages, session, delegate)
//        guard let msg = self.message else {
//            return
//        }
//        self.view.setMessage(msg, session, delegate)
//    }
//
//}

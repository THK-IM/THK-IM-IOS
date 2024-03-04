//
//  IMAudioMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/5.
//

import UIKit
import CocoaLumberjack
import Kingfisher

class IMAudioMsgCell: IMBaseMsgCell {
    
    private lazy var view : IMAudioMsgView = {
        let view = IMAudioMsgView()
        return view
    }()
    
    
    private lazy var statusView: UIImageView = {
        let view = UIImageView()
        view.layer.masksToBounds = true
        view.layer.cornerRadius = 4
        view.layer.backgroundColor = UIColor.red.cgColor
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

//
//  IMUnsupportMsgView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/24.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import CocoaLumberjack
import RxSwift

class IMUnSupportMsgView: IMMsgLabelView, IMsgBodyView {
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.sizeToFit()
        self.numberOfLines = 0
        self.font = UIFont.systemFont(ofSize: 14)
        self.padding = UIEdgeInsets.init(top: 4, left: 4, bottom: 4, right: 4)
    }
    
    func setMessage(_ message: Message, _ session: Session?, _ delegate: IMMsgCellOperator?, _ isReply: Bool = false) {
        self.text = ResourceUtils.loadString("not_support_msg_update_client", comment: "")
    }
    
    func contentView() -> UIView {
        return self
    }
}

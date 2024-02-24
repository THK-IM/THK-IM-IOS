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

class IMUnSupportMsgView: IMMsgLabelView, BaseMsgView {
    
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
        self.font = UIFont.boldSystemFont(ofSize: 14)
        self.padding = UIEdgeInsets.init(top: 4, left: 4, bottom: 4, right: 4)
    }
    
    func setMessage(_ message: Message, _ session: Session?, _ delegate: IMMsgCellOperator?, _ isReply: Bool = false) {
        self.text = "当前版本不支持该消息类型，请更新"
    }
}

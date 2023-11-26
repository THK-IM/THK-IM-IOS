//
//  IMRecordMsgCell.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/25.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit

class IMRecordMsgCell: BaseMsgCell {
    
    private lazy var recordTitleView: UILabel = {
        let view = UILabel()
        view.sizeToFit()
        view.numberOfLines = 0
        view.font = UIFont.systemFont(ofSize: 14)
        view.textColor = UIColor.init(hex: "222222")
        view.textAlignment = .left
        return view
    }()
    
    private lazy var recordContentView: UILabel = {
        let view = UILabel()
        view.sizeToFit()
        view.numberOfLines = 0
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.init(hex: "444444")
        view.textAlignment = .left
        return view
    }()
    
    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.init(hex: "666666")
        return view
    }()
    
    private lazy var descView: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
        view.font = UIFont.systemFont(ofSize: 12)
        view.textColor = UIColor.init(hex: "444444")
        view.textAlignment = .left
        return view
    }()
    
    private lazy var recordView: UIView = {
        let view = UIView()
        view.addSubview(self.recordTitleView)
        view.addSubview(self.recordContentView)
        view.addSubview(self.lineView)
        view.addSubview(self.descView)
        return view
    }()
    
    override func msgView() -> UIView {
        return self.recordView
    }
    
    override func hasBubble() -> Bool {
        return true
    }
    
    open override func setMessage(_ position: Int, _ messages: Array<Message>, _ session: Session, _ delegate: IMMsgCellOperator) {
        super.setMessage(position, messages, session, delegate)
        guard let msg = self.message else {
            return
        }
        guard let content = message?.content else {
            return
        }
        guard let recordBody = try? JSONDecoder().decode(IMRecordMsgBody.self, from: content.data(using: .utf8) ?? Data()) else {
            return
        }
        let size = IMUIManager.shared.getMsgCellProvider(msg.type).viewSize(msg)
        self.recordView.removeConstraints(self.recordView.constraints)
        self.recordView.snp.makeConstraints { make in
            make.height.equalTo(size.height)
            make.width.greaterThanOrEqualTo(200)
        }
        
        self.recordTitleView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(4)
            make.left.equalToSuperview().offset(4)
            make.right.equalToSuperview().offset(-4)
            make.height.equalTo(16)
        }
        
        self.descView.snp.makeConstraints { make in
            make.bottom.equalToSuperview().offset(-4)
            make.left.equalToSuperview().offset(4)
            make.right.equalToSuperview().offset(-4)
            make.height.equalTo(16)
        }
        
        self.lineView.snp.makeConstraints { make in
            make.bottom.equalTo(self.descView.snp.top)
            make.left.equalToSuperview().offset(4)
            make.right.equalToSuperview().offset(-4)
            make.height.equalTo(1)
        }
        
        self.recordContentView.snp.makeConstraints { make in
            make.top.equalTo(self.recordTitleView.snp.bottom)
            make.left.equalToSuperview().offset(4)
            make.right.equalToSuperview().offset(-4)
            make.bottom.equalTo(self.lineView.snp.top)
        }
        
        self.recordTitleView.text = recordBody.title
        self.recordContentView.text = recordBody.content
        self.descView.text = "聊天记录"
    }
    
    
}


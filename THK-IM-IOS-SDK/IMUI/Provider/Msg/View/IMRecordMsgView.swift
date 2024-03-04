//
//  IMRecordMsgView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/24.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import CocoaLumberjack
import RxSwift

class IMRecordMsgView: UIView, IMsgBodyView {
    
    private weak var delegate: IMMsgCellOperator?
    private var message: Message?
    
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
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.addSubview(self.recordTitleView)
        self.addSubview(self.recordContentView)
        self.addSubview(self.lineView)
        self.addSubview(self.descView)
    }
    
    func setMessage(_ message: Message, _ session: Session?, _ delegate: IMMsgCellOperator?, _ isReply: Bool = false) {
        guard let content = message.content else {
            return
        }
        guard let recordBody = try? JSONDecoder().decode(IMRecordMsgBody.self, from: content.data(using: .utf8) ?? Data()) else {
            return
        }
        let provider = IMUIManager.shared.getMsgCellProvider(message.type)
        let size = isReply ? provider.replyMsgViewSize(message, session) : provider.viewSize(message, session)
        self.removeConstraints(self.constraints)
        
        var padding = 0
        if isReply {
            self.snp.makeConstraints { make in
                make.edges.equalToSuperview()
            }
            self.recordTitleView.textColor = .darkGray
            self.recordTitleView.font = UIFont.systemFont(ofSize: 12)
            self.recordContentView.textColor = .darkGray
            self.recordContentView.font = UIFont.systemFont(ofSize: 12)
            self.descView.textColor = .darkGray
            self.descView.font = UIFont.systemFont(ofSize: 12)
            self.lineView.backgroundColor = .darkGray
        } else {
            padding = 4
            self.snp.makeConstraints { make in
                make.height.equalTo(size.height)
                make.width.equalTo(size.width)
            }
        }
        
        self.recordTitleView.snp.makeConstraints { make in
            make.height.equalTo(14).priority(.required)
            make.top.equalToSuperview().offset(padding)
            make.left.equalToSuperview().offset(padding)
            make.right.equalToSuperview().offset(0-padding)
        }
        
        self.descView.snp.makeConstraints { make in
            make.height.equalTo(14).priority(.required)
            make.bottom.equalToSuperview().offset(-2)
            make.left.equalToSuperview().offset(padding)
            make.right.equalToSuperview().offset(0-padding)
        }
        
        self.lineView.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.bottom.equalTo(sf.descView.snp.top)
            make.left.equalToSuperview().offset(padding)
            make.right.equalToSuperview().offset(0-padding)
            make.height.equalTo(1).priority(.required)
        }
        
        self.recordContentView.snp.makeConstraints { [weak self] make in
            guard let sf = self else {
                return
            }
            make.top.equalTo(sf.recordTitleView.snp.bottom)
            make.left.equalToSuperview().offset(padding)
            make.right.equalToSuperview().offset(0-padding)
            make.bottom.equalTo(sf.lineView.snp.top)
        }
        
        self.recordTitleView.text = recordBody.title
        self.recordContentView.text = recordBody.content
        self.descView.text = "聊天记录"
    }
    
    func contentView() -> UIView {
        return self
    }
    
    
}

//
//  IMRecordMsgView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/24.
//  Copyright © 2024 THK. All rights reserved.
//

import CocoaLumberjack
import RxSwift
import UIKit

class IMRecordMsgView: UIView, IMsgBodyView {

    private weak var delegate: IMMsgCellOperator?
    private var message: Message?

    private lazy var recordTitleView: UILabel = {
        let view = UILabel()
        view.sizeToFit()
        view.numberOfLines = 0
        view.textAlignment = .left
        return view
    }()

    private lazy var recordContentView: UILabel = {
        let view = UILabel()
        view.sizeToFit()
        view.numberOfLines = 0
        view.textAlignment = .left
        return view
    }()

    private lazy var lineView: UIView = {
        let view = UIView()
        view.backgroundColor = UIColor.init(hex: "CCCCCC")
        return view
    }()

    private lazy var descView: UILabel = {
        let view = UILabel()
        view.numberOfLines = 0
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

    func setMessage(
        _ message: Message, _ session: Session?, _ delegate: IMMsgCellOperator?,
        _ isReply: Bool = false
    ) {
        guard let content = message.content else {
            return
        }
        guard
            let recordBody = try? JSONDecoder().decode(
                IMRecordMsgBody.self, from: content.data(using: .utf8) ?? Data())
        else {
            return
        }
        let padding = isReply ? 4 : 8
        self.recordTitleView.snp.remakeConstraints { make in
            make.top.equalToSuperview().offset(padding)
            make.left.equalToSuperview().offset(padding)
            make.right.equalToSuperview().offset(0 - padding)
            make.height.equalTo(16)
        }
        self.recordContentView.snp.makeConstraints { make in
            make.top.equalTo(self.recordTitleView.snp.bottom).offset(padding / 2)
            make.left.equalToSuperview().offset(padding)
            make.right.equalToSuperview().offset(0 - padding)
            make.height.lessThanOrEqualTo(60)
        }
        self.lineView.snp.remakeConstraints { make in
            make.top.equalTo(self.recordContentView.snp.bottom).offset(padding / 2)
            make.left.equalToSuperview().offset(padding)
            make.right.equalToSuperview().offset(0 - padding)
            make.height.equalTo(1)
        }
        self.descView.snp.remakeConstraints { make in
            make.top.equalTo(self.lineView.snp.bottom).offset(padding / 2)
            make.bottom.equalToSuperview().offset(-padding)
            make.left.equalToSuperview().offset(padding)
            make.right.equalToSuperview().offset(0 - padding)
            make.height.equalTo(14)
        }

        self.recordTitleView.text = recordBody.title
        self.recordContentView.text = recordBody.content
        self.descView.text = ResourceUtils.loadString("chat_record", comment: "")

        if isReply {
            self.recordTitleView.font = UIFont.boldSystemFont(ofSize: 12)
            self.recordTitleView.textColor = UIColor.init(hex: "999999")
            self.recordContentView.font = UIFont.boldSystemFont(ofSize: 12)
            self.recordContentView.textColor = UIColor.init(hex: "999999")
            self.descView.font = UIFont.boldSystemFont(ofSize: 12)
            self.descView.textColor = UIColor.init(hex: "999999")
        } else {
            self.recordTitleView.font = UIFont.boldSystemFont(ofSize: 14)
            self.recordTitleView.textColor = UIColor.init(hex: "222222")
            self.recordContentView.font = UIFont.systemFont(ofSize: 12)
            self.recordContentView.textColor = UIColor.init(hex: "666666")
            self.descView.font = UIFont.systemFont(ofSize: 12)
            self.descView.textColor = UIColor.init(hex: "444444")
        }
    }

    func contentView() -> UIView {
        return self
    }

}

//
//  IMMsgReplyView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/24.
//  Copyright © 2024 THK. All rights reserved.
//

import RxSwift
import UIKit

open class IMMsgReplyView: UIView {

    weak var sender: IMMsgSender? = nil
    private let disposeBag = DisposeBag()
    private var message: Message? = nil

    override init(frame: CGRect) {
        super.init(frame: frame)
    }

    lazy private var lineView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.backgroundColor =
            IMUIManager.shared.uiResourceProvider?.tintColor() ?? UIColor.init(hex: "#ff08AAFF")
        return view
    }()

    lazy private var nickView: UILabel = {
        let view = UILabel()
        view.textColor =
            IMUIManager.shared.uiResourceProvider?.tintColor() ?? UIColor.init(hex: "#ff08AAFF")
        view.font = UIFont.systemFont(ofSize: 13)
        view.textAlignment = .left
        view.numberOfLines = 1
        return view
    }()

    private var replyMsgView = UIView()

    required public init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setRelyContent(
        _ nickname: String, _ msg: Message, _ session: Session?, _ delegate: IMMsgCellOperator?
    ) {
        self.removeAllSubviews()
        self.nickView.text = nickname
        let attributes = [NSAttributedString.Key.font: self.nickView.font]
        let textSize = (self.nickView.text! as NSString).size(
            withAttributes: attributes as [NSAttributedString.Key: Any])
        let maxWidth = IMUIManager.shared.getMsgCellProvider(msg.type).cellMaxWidth() - 16
        self.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.width.greaterThanOrEqualTo(textSize.width + 16)
            make.width.lessThanOrEqualTo(maxWidth)
        }

        self.addSubview(self.nickView)
        self.addSubview(self.lineView)
        self.addSubview(self.replyMsgView)

        self.lineView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.bottom.equalToSuperview().offset(-6)
            make.left.equalToSuperview().offset(6)
            make.width.equalTo(4)
        }

        self.nickView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(6)
            make.height.equalTo(14)
            make.left.equalTo(self.lineView.snp.right).offset(6)
            make.right.equalToSuperview().offset(-6)
        }
        self.replyMsgView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(24)
            make.bottom.equalToSuperview().offset(-6)
            make.left.equalTo(self.lineView.snp.right).offset(6)
            make.right.equalToSuperview().offset(-6)
        }

        let iMsgBodyView = IMUIManager.shared.getMsgCellProvider(msg.type).replyMsgView(
            msg, session, delegate)
        let view = iMsgBodyView.contentView()
        self.replyMsgView.addSubview(view)
        view.snp.makeConstraints { make in
            make.left.top.bottom.equalToSuperview()
            make.right.lessThanOrEqualToSuperview()
        }
        iMsgBodyView.setMessage(msg, session, delegate, true)
    }

    func clearReplyContent() {
        self.removeAllSubviews()
        self.snp.remakeConstraints { make in
            make.top.equalToSuperview()
            make.left.right.equalToSuperview()
            make.height.equalTo(0)
        }
    }

    private func removeAllSubviews() {
        self.replyMsgView.subviews.forEach { v in
            v.removeFromSuperview()
        }
        self.subviews.forEach { v in
            v.removeFromSuperview()
        }
    }

}

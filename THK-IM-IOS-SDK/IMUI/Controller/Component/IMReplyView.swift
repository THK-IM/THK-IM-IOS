//
//  IMReplyView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/23.
//  Copyright © 2024 THK. All rights reserved.
//

import RxSwift
import UIKit

class IMReplyView: UIView {

    weak var sender: IMMsgSender? = nil
    private let disposeBag = DisposeBag()
    private var message: Message? = nil

    lazy private var closeView: UIImageView = {
        let view = UIImageView()
        view.image = ResourceUtils.loadImage(named: "ic_close")?.withTintColor(
            IMUIManager.shared.uiResourceProvider?.inputTextColor()
                ?? UIColor.init(hex: "333333")
        ).scaledToSize(
            CGSize(width: 16, height: 16))
        view.contentMode = .scaleAspectFill
        return view
    }()

    lazy private var lineView: UIView = {
        let view = UIView()
        view.layer.cornerRadius = 2
        view.backgroundColor =
            IMUIManager.shared.uiResourceProvider?.tintColor()
        return view
    }()

    lazy private var replyUserView: UILabel = {
        let view = UILabel()
        view.textColor =
            IMUIManager.shared.uiResourceProvider?.inputTextColor()
            ?? UIColor.init(hex: "333333")
        view.font = UIFont.systemFont(ofSize: 15)
        view.textAlignment = .left
        view.numberOfLines = 1
        return view
    }()

    lazy private var replyMsgView: UILabel = {
        let view = UILabel()
        view.textColor =
            IMUIManager.shared.uiResourceProvider?.tipTextColor()
            ?? UIColor.init(hex: "666666")
        view.font = UIFont.systemFont(ofSize: 13)
        view.textAlignment = .justified
        view.numberOfLines = 2
        return view
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        self.addSubview(self.lineView)
        self.addSubview(self.closeView)
        self.addSubview(self.replyUserView)
        self.addSubview(self.replyMsgView)
        self.closeView.rx.tapGesture().when(.ended).asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.sender?.closeReplyMessage()
            }).disposed(by: self.disposeBag)
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func setMessage(_ msg: Message) {
        self.message = msg
    }

    func resetLayout() {
        if let msg = self.message {
            self.lineView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(2)
                make.bottom.equalToSuperview().offset(-2)
                make.left.equalToSuperview().offset(12)
                make.width.equalTo(4)
            }
            self.closeView.snp.remakeConstraints { make in
                make.right.equalToSuperview().offset(-12)
                make.size.equalTo(30)
                make.centerY.equalToSuperview()
            }
            self.replyUserView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(2)
                make.left.equalTo(self.lineView.snp.right).offset(6)
                make.right.equalTo(self.closeView.snp.left).offset(-6)
                make.height.equalTo(14)
            }
            self.replyMsgView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(20)
                make.left.equalTo(self.lineView.snp.right).offset(6)
                make.right.equalTo(self.closeView.snp.left).offset(-6)
                make.bottom.equalToSuperview().offset(-2)
            }
            if let member = sender?.syncGetSessionMemberInfo(msg.fromUId) {
                if member.1?.noteName != nil && member.1!.noteName!.count > 0 {
                    self.showContentView(member.1!.noteName!, msg)
                } else {
                    self.showContentView(member.0.nickname, msg)
                }
            } else {
                IMCoreManager.shared.userModule.queryUser(id: msg.fromUId)
                    .compose(RxTransformer.shared.io2Main())
                    .subscribe(onNext: { [weak self] user in
                        self?.showContentView(user.nickname, msg)
                    })
                    .disposed(by: self.disposeBag)
            }

        } else {
            self.closeView.snp.remakeConstraints { make in
                make.height.equalToSuperview()
            }
            self.lineView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(0)
                make.bottom.equalToSuperview().offset(-0)
                make.height.equalToSuperview()
            }
            self.replyUserView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(0)
                make.height.equalToSuperview()
            }
            self.replyMsgView.snp.remakeConstraints { make in
                make.top.equalToSuperview().offset(0)
                make.height.equalToSuperview()
            }
        }
    }

    private func showContentView(_ nickname: String, _ msg: Message) {
        self.replyUserView.text = "\(nickname)"
        self.replyMsgView.text = IMCoreManager.shared.messageModule
            .getMsgProcessor(msg.type)
            .msgDesc(msg: msg)
    }

    func clearMessage() {
        self.message = nil
        self.resetLayout()
    }

    func getReplyMessage() -> Message? {
        return self.message
    }

}

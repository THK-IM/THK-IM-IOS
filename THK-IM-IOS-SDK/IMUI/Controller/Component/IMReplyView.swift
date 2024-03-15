//
//  IMReplyView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/23.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import RxSwift

class IMReplyView: UIView {
    
    weak var sender: IMMsgSender? = nil
    private let disposeBag = DisposeBag()
    private var message: Message? = nil
    
    lazy private var closeView: UIImageView = {
        let view = UIImageView()
        view.image = UIImage(named: "ic_reply_close")
        view.contentMode = .scaleAspectFill
        return view
    }()
    
    lazy private var lineView: UIImageView = {
        let view = UIImageView()
        view.image = Bubble().drawRectWithRoundedCorner(
            radius: 2, borderWidth: 0, backgroundColor: UIColor.init(hex: "#ff999999"),
            borderColor: UIColor.init(hex: "#ff999999"), width: 4, height: 30, pos: 0)
        return view
    }()
    
    lazy private var replyUserView: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.darkGray
        view.font = UIFont.systemFont(ofSize: 12)
        view.textAlignment = .justified
        view.numberOfLines = 1
        return view
    }()
    
    lazy private var replyMsgView: UILabel = {
        let view = UILabel()
        view.textColor = UIColor.darkGray
        view.font = UIFont.systemFont(ofSize: 12)
        view.textAlignment = .justified
        view.numberOfLines = 1
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
        self.addSubview(self.lineView)
        self.addSubview(self.closeView)
        self.addSubview(self.replyUserView)
        self.addSubview(self.replyMsgView)
    }
    
    func setMessage(_ msg: Message) {
        self.message = msg
        self.closeView.rx.tapGesture().when(.ended).asObservable()
            .subscribe(onNext: { [weak self] _ in
                self?.sender?.closeReplyMessage()
            }).disposed(by: self.disposeBag)
    }
    
//    override func layoutSubviews() {
//        requestLayout()
//    }
    
    func requestLayout() {
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
            self.replyUserView.snp.remakeConstraints { [weak self] make in
                guard let sf = self else {
                    return
                }
                make.top.equalToSuperview().offset(2)
                make.left.equalTo(sf.lineView.snp.right).offset(6)
                make.right.equalTo(sf.closeView.snp.left).offset(-6)
                make.height.equalTo(14)
            }
            self.replyMsgView.snp.remakeConstraints { [weak self] make in
                guard let sf = self else {
                    return
                }
                make.top.equalToSuperview().offset(16)
                make.left.equalTo(sf.lineView.snp.right).offset(6)
                make.right.equalTo(sf.closeView.snp.left).offset(-6)
                make.bottom.equalToSuperview().offset(-2)
            }
            IMCoreManager.shared.userModule.queryUser(id: msg.fromUId)
                .compose(RxTransformer.shared.io2Main())
                .subscribe(onNext: { [weak self] user in
                    self?.showContentView(user, msg)
                })
                .disposed(by: self.disposeBag)
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
    
    private func showContentView(_ user: User, _ msg: Message) {
        self.replyUserView.text = "\(user.nickname)"
        Observable.just("")
            .flatMap { it in
                let sessionDesc = IMCoreManager.shared.messageModule.getMsgProcessor(msg.type).sessionDesc(msg: msg)
                return Observable.just(sessionDesc)
            }.compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] msg in
                self?.replyMsgView.text = msg
            }).disposed(by: self.disposeBag)
    }
    
    func clearMessage() {
        self.message = nil
    }
    
    func getReplyMessage() -> Message? {
        return self.message
    }

    
}

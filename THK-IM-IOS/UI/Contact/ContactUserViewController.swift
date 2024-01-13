//
//  ContactUserViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/10.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import RxSwift

class ContactUserViewController: BaseViewController {
    
    static func open(_ uiViewController: UIViewController, _ user: User) {
        let contractUserController = ContactUserViewController()
        contractUserController.user = user
        contractUserController.hidesBottomBarWhenPushed = true
        uiViewController.navigationController?.pushViewController(contractUserController, animated: false)
    }
    
    private let headerView = UIView()
    private let avatarView = UIImageView()
    private let nicknameView = UILabel()
    private let accountView = UILabel()
    private let accountIdView = UILabel()
    var user: User? = nil
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.init(hex: "dcdcdc")
        self.setupUI()
    }
    
    private func setupUI() {
        self.view.addSubview(self.headerView)
        self.headerView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(200)
        }
        if let user = self.user {
            initHeader(user: user)
        }
    }
    
    private func initHeader(user: User) {
        self.headerView.addSubview(self.avatarView)
        self.headerView.addSubview(self.nicknameView)
        self.headerView.addSubview(self.accountView)
        self.headerView.addSubview(self.accountIdView)
        
        self.avatarView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(100)
            make.height.equalTo(60)
            make.width.equalTo(60)
        }
        self.avatarView.ca_setImageUrlWithCorner(url: user.avatar ?? "", radius: 0)
        
        self.nicknameView.snp.makeConstraints { make in
            make.left.equalTo(self.avatarView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(24)
            make.top.equalTo(self.avatarView.snp.top)
        }
        self.nicknameView.text = user.nickname
        self.nicknameView.textColor = UIColor.black
        self.nicknameView.font = UIFont.systemFont(ofSize: 20.0, weight: .bold)
        
        self.accountView.snp.makeConstraints { make in
            make.left.equalTo(self.avatarView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(20)
            make.top.equalTo(self.nicknameView.snp.bottom).offset(10)
        }
        self.accountView.text = "账户ID:"
        self.accountView.textColor = UIColor.init(hex: "666666")
        self.accountView.font = UIFont.systemFont(ofSize: 16.0)
        
        self.accountIdView.snp.makeConstraints { make in
            make.left.equalTo(self.avatarView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-100)
            make.height.equalTo(20)
            make.top.equalTo(self.accountView.snp.bottom)
        }
        self.accountIdView.text = user.displayId
        self.accountIdView.textColor = UIColor.init(hex: "666666")
        self.accountIdView.font = UIFont.systemFont(ofSize: 16.0)
        
        self.setupButtons()
    }
    
    private func setupButtons() {
        let followButton = UIButton(type: .custom)
        let followImage = Bubble().drawRectWithRoundedCorner(
            radius: 10.0, borderWidth: 0,
            backgroundColor: UIColor.init(hex: "3282F6"), borderColor: UIColor.init(hex: "3282F6"),
            width: 40, height: 40)
        let followPressedImage = Bubble().drawRectWithRoundedCorner(
            radius: 10.0, borderWidth: 0,
            backgroundColor: UIColor.init(hex: "3282F6", factor: 2), borderColor: UIColor.init(hex: "3282F6", factor: 2),
            width: 40, height: 40)
        self.view.addSubview(followButton)
        followButton.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(240)
        }
        followButton.setTitle("关注", for: .normal)
        followButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        followButton.setTitleColor(UIColor.white, for: .normal)
        followButton.setBackgroundImage(followImage, for: .normal)
        followButton.setBackgroundImage(followPressedImage, for: .highlighted)
        followButton.rx.tap.asObservable().subscribe(onNext: { [weak self] in
            self?.follow()
        }).disposed(by: self.disposeBag)
        
        let addFriendButton = UIButton(type: .custom)
        let addFriendImage = Bubble().drawRectWithRoundedCorner(
            radius: 10.0, borderWidth: 0,
            backgroundColor: UIColor.init(hex: "3282F6"), borderColor: UIColor.init(hex: "3282F6"),
            width: 40, height: 40)
        let addFriendPressedImage = Bubble().drawRectWithRoundedCorner(
            radius: 10.0, borderWidth: 0,
            backgroundColor: UIColor.init(hex: "3282F6", factor: 2), borderColor: UIColor.init(hex: "3282F6", factor: 2),
            width: 40, height: 40)
        self.view.addSubview(addFriendButton)
        addFriendButton.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(300)
        }
        addFriendButton.setTitle("添加好友", for: .normal)
        addFriendButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        addFriendButton.setTitleColor(UIColor.white, for: .normal)
        addFriendButton.setBackgroundImage(addFriendImage, for: .normal)
        addFriendButton.setBackgroundImage(addFriendPressedImage, for: .highlighted)
        addFriendButton.rx.tap.asObservable().subscribe(onNext: { [weak self] in
            self?.addFriend()
        }).disposed(by: self.disposeBag)
        
        let sendMsgButton = UIButton(type: .custom)
        let sendMsgImage = Bubble().drawRectWithRoundedCorner(
            radius: 10.0, borderWidth: 0,
            backgroundColor: UIColor.init(hex: "3282F6"), borderColor: UIColor.init(hex: "3282F6"),
            width: 40, height: 40)
        let sendMsgPressedImage = Bubble().drawRectWithRoundedCorner(
            radius: 10.0, borderWidth: 0,
            backgroundColor: UIColor.init(hex: "3282F6", factor: 2), borderColor: UIColor.init(hex: "3282F6", factor: 2),
            width: 40, height: 40)
        self.view.addSubview(sendMsgButton)
        sendMsgButton.snp.makeConstraints { make in
            make.height.equalTo(40)
            make.left.equalToSuperview().offset(20)
            make.right.equalToSuperview().offset(-20)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(360)
        }
        sendMsgButton.setTitle("发送消息", for: .normal)
        sendMsgButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        sendMsgButton.setTitleColor(UIColor.white, for: .normal)
        sendMsgButton.setBackgroundImage(sendMsgImage, for: .normal)
        sendMsgButton.setBackgroundImage(sendMsgPressedImage, for: .highlighted)
        sendMsgButton.rx.tap.asObservable().subscribe(onNext: { [weak self] in
            self?.sendMsg()
        }).disposed(by: self.disposeBag)
    }
    
    private func follow() {
        guard let user = self.user else {
            return
        }
        if let uId = DataRepository.shared.getUserId() {
            let req = FollowVo(uId: uId, contactId: user.id)
            DataRepository.shared.contactApi.rx
                .request(.follow(req))
                .asObservable()
                .compose(RxTransformer.shared.response2Void())
                .compose(RxTransformer.shared.io2Main())
                .subscribe(onNext: { [weak self] _ in
                    self?.showToast("关注成功")
                }).disposed(by: self.disposeBag)
        }
        
    }
    
    private func addFriend() {
        guard let user = self.user else {
            return
        }
        if let uId = DataRepository.shared.getUserId() {
            let req = ApplyFriendVo(uId: uId, contactId: user.id, channel: nil, msg: nil)
            DataRepository.shared.contactApi.rx
                .request(.applyFriend(req))
                .asObservable()
                .compose(RxTransformer.shared.response2Void())
                .compose(RxTransformer.shared.io2Main())
                .subscribe(onNext: { [weak self] _ in
                    self?.showToast("好友申请发送成功")
                }).disposed(by: self.disposeBag)
        }
        
    }
    
    private func sendMsg() {
        guard let user = self.user else {
            return
        }
        if let uId = DataRepository.shared.getUserId() {
            let req = ContactSessionCreateVo(uId: uId, contactId: user.id)
            DataRepository.shared.contactApi.rx
                .request(.createContactSession(req))
                .asObservable()
                .compose(RxTransformer.shared.response2Bean(SessionVo.self))
                .compose(RxTransformer.shared.io2Main())
                .flatMap({ sessionVo -> Observable<Session> in
                    let session = sessionVo.toSession()
                    try? IMCoreManager.shared.database.sessionDao().insertOrUpdate([session])
                    return Observable.just(session)
                })
                .subscribe(onNext: { [weak self] session in
                    if let sf = self {
                        IMUIManager.shared.pageRouter?.openSession(controller: sf, session: session)
                    }
                }).disposed(by: self.disposeBag)
        }
    }
    
}

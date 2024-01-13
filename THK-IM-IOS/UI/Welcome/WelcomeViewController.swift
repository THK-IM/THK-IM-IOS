//
//  WelcomeViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/5.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import CocoaLumberjack

class WelcomeViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.white
        let logoView = UIImageView()
        self.view.addSubview(logoView)
        logoView.image = UIImage(named: "AppLogo")
        
        logoView.snp.makeConstraints { make in
            make.height.equalTo(300)
            make.width.equalTo(300)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(110)
        }
        
        if let token = DataRepository.shared.getUserToken() {
            if let user = DataRepository.shared.getUser() {
                self.initIM(token: token, uId: user.id)
            } else {
                self.loginByToken(token: token)
            }
        } else {
//            let token = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJleHBpcmVzQXQiOjE3MDQ4NjkzMDIsImlkIjoiZDh6MGZ5Mmg3Y2d4IiwiaXNzdWVyIjoidXNlcl9zZXJ2ZXIifQ.jMPGAtEVysVOfcRk69b1NXGwJzyAYWAOrQkEkPyI5ao"
//            self.loginByToken(token: token)
            self.showLoginUI()
        }
    }
    
    private func showLoginUI() {
        let loginButton = UIButton(type: .custom)
        let loginImage = Bubble().drawRectWithRoundedCorner(
            radius: 10.0, borderWidth: 1,
            backgroundColor: UIColor.init(hex: "FF00FFFF"), borderColor: UIColor.init(hex: "FF00FFFF"),
            width: 60, height: 60)
        let loginPressedImage = Bubble().drawRectWithRoundedCorner(
            radius: 10.0, borderWidth: 1,
            backgroundColor: UIColor.init(hex: "FF00FFFF", factor: 2), borderColor: UIColor.init(hex: "FF00FFFF", factor: 2),
            width: 60, height: 60)
        self.view.addSubview(loginButton)
        loginButton.snp.makeConstraints { make in
            make.height.equalTo(60)
            make.width.equalTo(300)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-240)
        }
        loginButton.setTitle("登录", for: .normal)
        loginButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        loginButton.setTitleColor(UIColor.white, for: .normal)
        loginButton.setBackgroundImage(loginImage, for: .normal)
        loginButton.setBackgroundImage(loginPressedImage, for: .highlighted)
        
        
        let accountRegisterButton = UIButton(type: .custom)
        let accountRegisterImage = Bubble().drawRectWithRoundedCorner(
            radius: 10.0, borderWidth: 1,
            backgroundColor: UIColor.init(hex: "FF000000"), borderColor: UIColor.init(hex: "FF000000"),
            width: 60, height: 60)
        let accountRegisterPressedImage = Bubble().drawRectWithRoundedCorner(
            radius: 10.0, borderWidth: 1,
            backgroundColor: UIColor.init(hex: "FF000000", factor: 2), borderColor: UIColor.init(hex: "FF000000", factor: 2),
            width: 60, height: 60)
        self.view.addSubview(accountRegisterButton)
        accountRegisterButton.snp.makeConstraints { make in
            make.height.equalTo(60)
            make.width.equalTo(300)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-160)
        }
        accountRegisterButton.setTitle("账号注册", for: .normal)
        accountRegisterButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        accountRegisterButton.setTitleColor(UIColor.white, for: .normal)
        accountRegisterButton.setBackgroundImage(accountRegisterImage, for: .normal)
        accountRegisterButton.setBackgroundImage(accountRegisterPressedImage, for: .highlighted)
        
        let quickRegisterButton = UIButton(type: .custom)
        let quickRegisterImage = Bubble().drawRectWithRoundedCorner(
            radius: 10.0, borderWidth: 1,
            backgroundColor: UIColor.init(hex: "FFFF0000"), borderColor: UIColor.init(hex: "FFFF0000"),
            width: 60, height: 60)
        let quickRegisterPressedImage = Bubble().drawRectWithRoundedCorner(
            radius: 10.0, borderWidth: 1,
            backgroundColor: UIColor.init(hex: "FFFF0000", factor: 2), borderColor: UIColor.init(hex: "FFFF0000", factor: 2),
            width: 60, height: 60)
        self.view.addSubview(quickRegisterButton)
        quickRegisterButton.snp.makeConstraints { make in
            make.height.equalTo(60)
            make.width.equalTo(300)
            make.centerX.equalToSuperview()
            make.bottom.equalToSuperview().offset(-80)
        }
        quickRegisterButton.setTitle("快速注册", for: .normal)
        quickRegisterButton.titleLabel?.font = UIFont.systemFont(ofSize: 20, weight: .bold)
        quickRegisterButton.setTitleColor(UIColor.white, for: .normal)
        quickRegisterButton.setBackgroundImage(quickRegisterImage, for: .normal)
        quickRegisterButton.setBackgroundImage(quickRegisterPressedImage, for: .highlighted)
        quickRegisterButton.rx.tap.asObservable().subscribe(onNext: { [weak self] in
            self?.quickRegister()
        }).disposed(by: self.disposeBag)
    }
    
    
    func quickRegister() {
        let registerReq = RegisterReq()
        DataRepository.shared.userApi.rx.request(.register(registerReq))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(RegisterVo.self))
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] registerVo in
                self?.saveUserInfo(token: registerVo.token, user: registerVo.user)
            }, onError: { error in
                DDLogError("quickRegister \(error)")
            }).disposed(by: self.disposeBag)
    }
    
    
    func loginByToken(token: String) {
        DataRepository.shared.updateToken(token: token)
        let tokenLoginReq = TokenLoginReq(token: token)
        DataRepository.shared.userApi.rx.request(.loginByToken(tokenLoginReq))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(LoginVo.self))
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] loginVo in
                self?.saveUserInfo(token: loginVo.token ?? token, user: loginVo.user)
            }, onError: { error in
                if (error is CodeMessageError) {
                    DDLogError("loginByToken \(error) 2313131")
                }
            }).disposed(by: self.disposeBag)
        
    }
    
    func saveUserInfo(token: String, user: UserVo) {
        DataRepository.shared.saveUserInfo(token: token, userVo: user)
        DataRepository.shared.updateToken(token: token)
        self.initIM(token: token, uId: user.id)
    }
    
    func initIM(token: String, uId: Int64) {
        DataRepository.shared.updateToken(token: token)
        let delegate = UIApplication.shared.delegate as? AppDelegate
        delegate?.initIM(token: token, uId: uId)
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { success in
                let mainVc = MainViewController()
                let window = AppUtils.getWindow()
                window?.rootViewController = mainVc
            }).disposed(by: self.disposeBag)
    }
    
}

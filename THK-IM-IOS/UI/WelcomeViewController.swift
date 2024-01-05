//
//  WelcomeViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/5.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class WelcomeViewController: IMBaseViewController {
    
    override func viewDidLoad() {
        let logoView = UIImageView()
        self.view.addSubview(logoView)
        logoView.image = UIImage(named: "AppLogo")
        
        logoView.snp.makeConstraints { make in
            make.height.equalTo(300)
            make.width.equalTo(300)
            make.centerX.equalToSuperview()
            make.top.equalToSuperview().offset(110)
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
    }
    
}

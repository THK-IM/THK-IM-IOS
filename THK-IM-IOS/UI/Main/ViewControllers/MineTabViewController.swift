//
//  MineTabViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class MineTabViewController: BaseViewController {

    private let headerView = UIView()
    private let avatarView = UIImageView()
    private let nicknameView = UILabel()
    private let accountView = UILabel()
    private let accountIdView = UILabel()
    private let qrcodeView = UIImageView()
    private let arrowView = UIImageView()
    private let settingView = NavigationItemLayout()
    private let aboutView = NavigationItemLayout()

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.init(hex: "eeeeee")
        self.initUI()
    }

    private func initUI() {
        self.view.addSubview(self.headerView)
        self.headerView.backgroundColor = UIColor.white
        self.headerView.snp.makeConstraints { make in
            make.left.equalToSuperview()
            make.top.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(200)
        }
        if let userVo = DataRepository.shared.getUser() {
            initHeader(userVo: userVo)
        }

        initNavigationLayouts()
    }

    private func initHeader(userVo: UserVo) {

        self.headerView.addSubview(self.avatarView)
        self.headerView.addSubview(self.nicknameView)
        self.headerView.addSubview(self.accountView)
        self.headerView.addSubview(self.accountIdView)
        self.headerView.addSubview(self.qrcodeView)
        self.headerView.addSubview(self.arrowView)

        self.avatarView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.top.equalToSuperview().offset(100)
            make.height.equalTo(60)
            make.width.equalTo(60)
        }
        self.avatarView.renderImageByUrlWithCorner(url: userVo.avatar ?? "", radius: 0)

        self.nicknameView.snp.makeConstraints { make in
            make.left.equalTo(self.avatarView.snp.right).offset(10)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(24)
            make.top.equalTo(self.avatarView.snp.top)
        }
        self.nicknameView.text = userVo.nickname
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
        self.accountIdView.text = userVo.displayId
        self.accountIdView.textColor = UIColor.init(hex: "666666")
        self.accountIdView.font = UIFont.systemFont(ofSize: 16.0)

        self.qrcodeView.snp.makeConstraints { make in
            make.left.equalTo(self.accountIdView.snp.right).offset(10)
            make.top.equalTo(self.accountIdView.snp.top)
            make.width.equalTo(20)
            make.height.equalTo(20)
        }
        self.qrcodeView.renderImageByUrlWithCorner(url: userVo.qrcode ?? "", radius: 0)

        self.arrowView.snp.makeConstraints { make in
            make.left.equalTo(self.qrcodeView.snp.right).offset(30)
            make.top.equalTo(self.accountIdView.snp.top)
            make.width.equalTo(20)
            make.height.equalTo(20)
        }
        self.arrowView.image = UIImage(named: "ic_arrow_right")

    }

    private func initNavigationLayouts() {
        self.view.addSubview(self.settingView)
        self.view.addSubview(self.aboutView)

        self.settingView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(240)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(60)
        }
        self.aboutView.snp.makeConstraints { make in
            make.top.equalTo(self.settingView.snp.bottom)
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.height.equalTo(60)
        }

        self.settingView.backgroundColor = UIColor.white
        self.aboutView.backgroundColor = UIColor.white

        self.settingView.setIconTitle(image: UIImage(named: "ic_setting"), title: "设置")
        self.aboutView.setIconTitle(image: UIImage(named: "ic_about"), title: "关于")

    }
}

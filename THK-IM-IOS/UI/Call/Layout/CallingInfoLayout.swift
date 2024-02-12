//
//  CallingInfoLayout.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class CallingInfoLayout: UIView {
    
    private let avatarView: UIImageView = {
        let v = UIImageView()
        v.contentMode = .scaleAspectFit
        return v
    }()
    
    private let nickerView: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 16)
        v.textColor = .white
        v.textAlignment = .center
        return v
    }()
    
    private let descView: UILabel = {
        let v = UILabel()
        v.font = UIFont.systemFont(ofSize: 14)
        v.textColor = .white
        return v
    }()
    
    override init(frame: CGRect) {
        super.init(frame: frame)
        self.setupUI()
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    private func setupUI() {
        self.addSubview(self.avatarView)
        self.avatarView.snp.makeConstraints { make in
            make.top.equalTo(100)
            make.height.equalTo(60)
            make.width.equalTo(60)
            make.centerX.equalToSuperview()
        }
        self.addSubview(self.nickerView)
        self.nickerView.snp.makeConstraints { make in
            make.top.equalTo(180)
            make.height.equalTo(20)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
        self.addSubview(self.descView)
        self.descView.snp.makeConstraints { make in
            make.top.equalTo(220)
            make.height.equalTo(20)
            make.width.equalToSuperview()
            make.centerX.equalToSuperview()
        }
    }
    
    func setUserInfo(user: User) {
        if let avatar = user.avatar {
            self.avatarView.ca_setImageUrlWithCorner(url: avatar, radius: 8)
        }
        self.nickerView.text = user.nickname
    }
    
}

//
//  NavigationItemLayout.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/7.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

public class NavigationItemLayout: UIView {

    private let iconView = UIImageView()
    private let titleView = UILabel()
    private let arrowView = UIImageView()

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        self.addSubview(self.iconView)
        self.addSubview(self.titleView)
        self.addSubview(self.arrowView)

        self.iconView.snp.makeConstraints { make in
            make.left.equalToSuperview().offset(10)
            make.centerY.equalToSuperview()
            make.width.equalTo(30)
            make.height.equalTo(30)
        }

        self.arrowView.snp.makeConstraints { make in
            make.right.equalToSuperview().offset(-10)
            make.centerY.equalToSuperview()
            make.width.equalTo(30)
            make.height.equalTo(30)
        }

        self.titleView.snp.makeConstraints { make in
            make.left.equalTo(self.iconView.snp.right).offset(10)
            make.right.equalTo(self.arrowView.snp.left).offset(-10)
            make.centerY.equalToSuperview()
            make.height.equalTo(30)
        }
        self.titleView.font = UIFont.systemFont(ofSize: 18)
        self.titleView.textColor = UIColor.init(hex: "333333")
    }

    func setIconTitle(image: UIImage?, title: String) {
        self.titleView.text = title
        self.iconView.image = image
        self.arrowView.image = UIImage(named: "ic_arrow_right")
    }
}

//
//  SearchViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/10.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class SearchViewController: BaseViewController {
    
    static func openSearchController(_ uiViewController: UIViewController, _ searchType: Int) {
        let searchViewController = SearchViewController()
        searchViewController.searchType = searchType
        searchViewController.hidesBottomBarWhenPushed = true
        uiViewController.navigationController?.pushViewController(searchViewController, animated: false)
    }
    
    var searchType = 0 // 1 搜索用户 2 搜索群
    private let textInputView = UITextField()
    private let cancelButton = UIButton()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.init(hex: "#dcdcdc")
        self.view.addSubview(self.textInputView)
        if searchType == 1 {
            self.textInputView.placeholder = "输入id搜索用户"
        } else {
            self.textInputView.placeholder = "输入id搜索群"
        }
        let statusHeight = AppUtils.getStatusBarHeight()
        self.textInputView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(statusHeight)
            make.left.equalToSuperview().offset(10)
            make.right.equalToSuperview().offset(-60)
            make.height.equalTo(40)
        }
        self.textInputView.textColor = UIColor.init(hex: "333333")
        self.textInputView.font = UIFont.systemFont(ofSize: 18)
        self.textInputView.backgroundColor = UIColor.white
        
        self.view.addSubview(self.cancelButton)
        self.cancelButton.snp.makeConstraints {make in
            make.top.equalToSuperview().offset(statusHeight)
            make.width.equalTo(40)
            make.right.equalToSuperview().offset(-10)
            make.height.equalTo(40)
        }
        self.cancelButton.setTitle("取消", for: .normal)
        self.cancelButton.setTitleColor(UIColor.init(hex: "666666"), for: .normal)
        self.cancelButton.addTarget(self, action: #selector(cancelTapped), for: .touchUpInside)
    }
    
    override func hasTitlebar() -> Bool {
        return false
    }
    
    @objc func cancelTapped() {
        self.navigationController?.popViewController(animated: true)
    }
}

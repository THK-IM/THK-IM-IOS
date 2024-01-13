//
//  SearchViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/10.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class SearchViewController: BaseViewController, UITextFieldDelegate {
    
    static func open(_ uiViewController: UIViewController, _ searchType: Int) {
        let searchViewController = SearchViewController()
        searchViewController.searchType = searchType
        searchViewController.hidesBottomBarWhenPushed = true
        uiViewController.navigationController?.pushViewController(searchViewController, animated: false)
    }
    
    var searchType = 0 // 1 搜索用户 2 搜索群
    private let cancelButton = UIButton()
    lazy private var textInputView: UITextField = {
        let textView = UITextField()
        textView.textColor = UIColor.init(hex: "333333")
        textView.delegate = self
        textView.font = UIFont.systemFont(ofSize: 16.0)
        textView.returnKeyType = .search
        textView.keyboardType = .default
        textView.backgroundColor = UIColor.white
        textView.leftView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 20))
        textView.leftViewMode = .always
        textView.rightView = UIView(frame: CGRect(x: 0, y: 0, width: 8, height: 20))
        textView.rightViewMode = .always
        return textView
    }()
    
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
        self.textInputView.text = "d86s4l3scyn5"
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
        
        self.textInputView.becomeFirstResponder()
    }
    
    override func hasTitlebar() -> Bool {
        return false
    }
    
    @objc func cancelTapped() {
        self.navigationController?.popViewController(animated: true)
    }
    
    func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        guard let keywords = textField.text else {
            return false
        }
        self.searchByKeywords(text: keywords)
        return true
    }
    
    private func searchByKeywords(text: String) {
        if (searchType == 1) {
            self.searchUser(id: text)
        } else {
            self.searchGroup(id: text)
        }
    }
    
    
    private func searchUser(id: String) {
        DataRepository.shared.userApi.rx.request(.searchUserByDisplayId(id))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(UserBasicInfoVo.self))
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] userBasicInfoVo in
                guard let sf = self else {
                    return
                }
                let user = userBasicInfoVo.toUser()
                ContactUserViewController.open(sf, user)
            }).disposed(by: self.disposeBag)
    }
    
    private func searchGroup(id: String) {
        DataRepository.shared.groupApi.rx.request(.searchGroup(id))
            .asObservable()
            .compose(RxTransformer.shared.response2Bean(GroupVo.self))
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { [weak self] groupVo in
                guard let sf = self else {
                    return
                }
                let group = groupVo.toGroup()
                GroupViewController.open(sf, group)
            }).disposed(by: self.disposeBag)
    }
        
}

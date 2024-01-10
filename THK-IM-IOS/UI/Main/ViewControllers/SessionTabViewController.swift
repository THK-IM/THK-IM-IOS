//
//  SessionTabViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class SessionTabViewController: IMSessionViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
        let statusBarHeight = AppUtils.getStatusBarHeight()
        let navigationItemHeight = self.navigationController?.navigationBar.frame.height ?? 0
        let top = statusBarHeight + navigationItemHeight
        self.view.subviews.first?.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(top)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
        setTitle(title: "Message")
        
        let searchIcon = UIImage(named: "ic_titlebar_search")?.scaledToSize(CGSize(width: 24, height: 24))
        setRightItems(images: [searchIcon], actions: [#selector(searchTapped)])
    }
    
    @objc func searchTapped() {
    }
    
}

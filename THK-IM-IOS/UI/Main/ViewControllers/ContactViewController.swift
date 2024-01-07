//
//  ContactViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class ContactViewController: BaseViewController {
    
    private let contactTableView = UITableView()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.contactTableView.backgroundColor = UIColor.white
        let statusBarHeight = AppUtils.getStatusBarHeight()
        let navigationItemHeight = self.navigationController?.navigationBar.frame.height ?? 0
        let top = statusBarHeight + navigationItemHeight
        self.view.addSubview(contactTableView)
        self.contactTableView.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(top)
            make.bottom.equalToSuperview()
            make.left.equalToSuperview()
            make.right.equalToSuperview()
        }
    }
    
    override func title() -> String? {
        return "Contact"
    }
    
    override func hasSearchMenu() -> Bool {
        return true
    }
}

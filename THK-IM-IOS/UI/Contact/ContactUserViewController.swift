//
//  ContactUserViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/10.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class ContactUserViewController: BaseViewController {
    
    static func open(_ uiViewController: UIViewController, _ user: User) {
        let contractUserController = ContactUserViewController()
        contractUserController.hidesBottomBarWhenPushed = true
        uiViewController.navigationController?.pushViewController(contractUserController, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
    }
    
}

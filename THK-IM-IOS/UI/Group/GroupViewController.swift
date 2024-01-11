//
//  GroupViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/11.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

import UIKit

class GroupViewController: BaseViewController {
    
    static func open(_ uiViewController: UIViewController, _ group: Group) {
        let groupController = GroupViewController()
        groupController.hidesBottomBarWhenPushed = true
        uiViewController.navigationController?.pushViewController(groupController, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
}

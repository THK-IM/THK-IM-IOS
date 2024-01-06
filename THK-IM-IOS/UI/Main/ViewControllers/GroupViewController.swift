//
//  GroupViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class GroupViewController: BaseViewController {
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
    
    override func title() -> String? {
        return "Group"
    }
    
    
    override func hasSearchMenu() -> Bool {
        return true
    }
    
    override func hasAddMenu() -> Bool {
        return true
    }
    
}

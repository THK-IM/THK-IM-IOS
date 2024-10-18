//
//  SessionTabViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class SessionTabViewController: IMSessionViewController {

    override func title() -> String? {
        return "Message"
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = UIColor.init(hex: "#EEEEEE")
    }

}

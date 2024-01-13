//
//  ExternalPageRouter.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/7.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

class ExternalPageRouter: IMPageRouter {
    
    func openSession(controller: UIViewController, session: Session) {
        let messageController = IMMessageViewController()
        messageController.hidesBottomBarWhenPushed = true
        messageController.session = session
        controller.navigationController?.pushViewController(messageController, animated: true)
    }
    
    func openUserPage(controller: UIViewController, user: User) {
        ContactUserViewController.open(controller, user)
    }
    
    func openGroupPage(controller: UIViewController, group: Group) {
        GroupViewController.open(controller, group, 1)
    }
    
    
    
}

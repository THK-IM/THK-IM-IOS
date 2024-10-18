//
//  IMPageRouter.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/7.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit

public protocol IMPageRouter {

    func openSession(controller: UIViewController, session: Session)

    func openUserPage(controller: UIViewController, user: User, session: Session)

    func openGroupPage(controller: UIViewController, group: Group, session: Session)

    func openLiveCall(controller: UIViewController, session: Session)

    func openMsgReadStatusPage(controller: UIViewController, session: Session, message: Message)
}

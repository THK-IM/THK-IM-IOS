//
//  ExternalPageRouter.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/7.
//  Copyright © 2024 THK. All rights reserved.
//

import UIKit
import RxSwift

class ExternalPageRouter: IMPageRouter {
    
    private let disposeBag = DisposeBag()
    
    func openLiveCall(controller: UIViewController, session: Session) {
        if session.type == SessionType.Single.rawValue {
            weak var vc = controller
            var ids = Set<Int64>()
            ids.insert(IMLiveManager.shared.selfId())
            ids.insert(session.entityId)
            IMLiveManager.shared.createRoom(ids: ids, mode: Mode.Video)
                .compose(RxTransformer.shared.io2Main())
                .subscribe(onNext: { room in
                    if vc != nil {
                        LiveCallViewController.presentLiveCallViewController(vc!, room)
                    }
                }).disposed(by: self.disposeBag)
        }
    }
    
    
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

//
//  ExternalPageRouter.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/7.
//  Copyright © 2024 THK. All rights reserved.
//

import RxSwift
import UIKit

class ExternalPageRouter: IMPageRouter {

    private let disposeBag = DisposeBag()

    func openLiveCall(controller: UIViewController, session: Session) {
        if session.type == SessionType.Single.rawValue {
            weak var vc = controller
            var ids = Set<Int64>()
            ids.insert(IMCoreManager.shared.uId)
            ids.insert(session.entityId)
            let mediaParams = MediaParams.R169_H2160
            RTCRoomManager.shared.createRoom(
                mode: RoomMode.Video, mediaParams: mediaParams
            )
            .compose(RxTransformer.shared.io2Main())
            .subscribe(onNext: { room in
                if vc != nil {
                    RTCRoomManager.shared.addRoom(room)
                    LiveCallViewController.popLiveCallViewController(
                        vc!, room.id, CallType.RequestCalling, ids)
                }
            }).disposed(by: self.disposeBag)
        }
    }

    func openSession(controller: UIViewController, session: Session) {
        let messageController = IMMessageViewController()
        messageController.hidesBottomBarWhenPushed = true
        messageController.session = session
        controller.navigationController?.pushViewController(
            messageController, animated: true)
    }

    func openUserPage(
        controller: UIViewController, user: User, session: Session
    ) {
        ContactUserViewController.open(controller, user)
    }

    func openGroupPage(
        controller: UIViewController, group: Group, session: Session
    ) {
        GroupViewController.open(controller, group, 1)
    }

    func openMsgReadStatusPage(
        controller: UIViewController, session: Session, message: Message
    ) {

    }

}

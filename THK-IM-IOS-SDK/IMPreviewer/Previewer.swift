//
//  Previewer.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/29.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

public class Previewer : IMPreviewer {
    
    private let disposeBag = DisposeBag()
    
    public init(token: String, endpoint: String) {
        AVCacheManager.shared.delegate = IMAVCacheProtocol(token: token, endpoint: endpoint)
    }
    
    public func previewMessage(_ controller: UIViewController, _ items: [Message], _ view: UIView, _ defaultId: Int64) {
        controller.definesPresentationContext = true
        let mediaPreviewController = IMMediaPreviewController()
        mediaPreviewController.messages = items
        let absoluteFrame = view.convert(view.bounds, to: nil)
        mediaPreviewController.enterFrame = absoluteFrame
        mediaPreviewController.defaultId = defaultId
        mediaPreviewController.modalPresentationStyle = .overFullScreen
        mediaPreviewController.transitioningDelegate = mediaPreviewController
        controller.present(mediaPreviewController, animated: true)
    }
    
    
    public func previewRecordMessage(_ controller: UIViewController, _ originSession: Session, _ message: Message) {
        if let recordMessage = try? JSONDecoder().decode(IMRecordMsgBody.self, from: message.content?.data(using: .utf8) ?? Data()) {
            Observable.just(message)
                .flatMap({ msg -> Observable<Array<Message>> in
                    var dbMsgs = Array<Message>()
                    for m in recordMessage.messages {
                        let dbMsg = try? IMCoreManager.shared.database.messageDao().findMessageByMsgId(m.msgId, m.sessionId)
                        if (dbMsg == nil) {
                            try? IMCoreManager.shared.database.messageDao().insertOrIgnoreMessages([m])
                            dbMsgs.append(m)
                        } else {
                            dbMsgs.append(dbMsg!)
                        }
                    }
                    return Observable.just(dbMsgs)
                })
                .compose(RxTransformer.shared.io2Main())
                .subscribe(onNext: { messages in
                    let recordVc = IMRecordMessageViewController()
                    recordVc.originSession = originSession
                    recordVc.recordMessages = messages
                    recordVc.recordTitle = recordMessage.title
                    recordVc.session = Session(id: 0, parentId: 0, type: SessionType.MsgRecord.rawValue, entityId: 0, name: "", remark: "", mute: 0, role: 0, status: 0, unreadCount: 0, topTimestamp: 0, cTime: 0, mTime: 0)
                    controller.navigationController?.pushViewController(recordVc, animated: true)
                }).disposed(by: self.disposeBag)
        }
    }
    
}

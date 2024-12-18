//
//  Previewer.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/29.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import RxSwift
import SJMediaCacheServer
import UIKit

public class Previewer: IMPreviewer {

    private let disposeBag = DisposeBag()

    public init(token: String, endpoint: String) {
        SJMediaCacheServer.shared().requestHandler = { request in
            if request.url?.absoluteString.hasPrefix(endpoint) == true {
                request.addValue(token, forHTTPHeaderField: APITokenInterceptor.tokenKey)
                request.addValue(
                    AppUtils.getDeviceName(), forHTTPHeaderField: APITokenInterceptor.deviceKey)
                request.addValue(
                    AppUtils.getTimezone(), forHTTPHeaderField: APITokenInterceptor.timezoneKey)
                request.addValue(
                    AppUtils.getLanguage(), forHTTPHeaderField: APITokenInterceptor.languageKey)
                request.addValue("IOS", forHTTPHeaderField: APITokenInterceptor.platformKey)
            }
        }
    }

    public func previewMessage(
        _ controller: UIViewController, _ items: [Message], _ view: UIView, _ loadMore: Bool,
        _ defaultId: Int64
    ) {
        controller.definesPresentationContext = true
        let mediaPreviewController = IMMediaPreviewController()
        mediaPreviewController.messages = items
        mediaPreviewController.loadMore = loadMore
        let absoluteFrame = view.convert(view.bounds, to: nil)
        mediaPreviewController.enterFrame = absoluteFrame
        mediaPreviewController.defaultId = defaultId
        mediaPreviewController.modalPresentationStyle = .overFullScreen
        mediaPreviewController.transitioningDelegate = mediaPreviewController
        controller.present(mediaPreviewController, animated: true)
    }

    public func previewRecordMessage(
        _ controller: UIViewController, _ originSession: Session, _ message: Message
    ) {
        if let recordMessage = try? JSONDecoder().decode(
            IMRecordMsgBody.self, from: message.content?.data(using: .utf8) ?? Data())
        {
            Observable.just(message)
                .flatMap({ msg -> Observable<[Message]> in
                    var dbMsgs = [Message]()
                    for m in recordMessage.messages {
                        let dbMsg = try? IMCoreManager.shared.database.messageDao().findByMsgId(
                            m.msgId, m.sessionId)
                        if dbMsg == nil {
                            try? IMCoreManager.shared.database.messageDao().insertOrIgnore([m])
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
                    recordVc.recordMessages = messages.sorted(by: { m1, m2 in
                        return m1.cTime < m2.cTime
                    })
                    recordVc.recordTitle = recordMessage.title
                    recordVc.session = Session.emptyTypeSession(SessionType.MsgRecord.rawValue)
                    controller.navigationController?.pushViewController(recordVc, animated: true)
                }).disposed(by: self.disposeBag)
        }
    }

}

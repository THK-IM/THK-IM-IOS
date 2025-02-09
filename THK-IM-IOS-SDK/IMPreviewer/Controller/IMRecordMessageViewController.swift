//
//  IMRecordMessageViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/26.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

class IMRecordMessageViewController: BaseViewController, IMMsgPreviewer {

    var recordTitle: String? = nil
    var recordMessages: [Message]? = nil
    var originSession: Session? = nil
    var session: Session? = nil
    private var messageLayout = IMMessageLayout()
    
    override func title() -> String? {
        return self.recordTitle
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = IMUIManager.shared.uiResourceProvider?.layoutBgColor()
        self.messageLayout.session = session
        self.messageLayout.mode = 1
        self.messageLayout.previewer = self
        self.view.addSubview(messageLayout)
        if let messages = self.recordMessages {
            let orderMessages = messages.sorted { m1, m2 in
                return m1.cTime > m2.cTime
            }
            self.messageLayout.addMessages(orderMessages)
        }
        self.initEvent()
        let top = self.getTitleBarHeight()
        messageLayout.snp.makeConstraints { make in
            make.top.equalToSuperview().offset(top)
            make.left.right.bottom.equalToSuperview()
        }
    }

    private func initEvent() {
        SwiftEventBus.onMainThread(
            self, name: IMEvent.MsgNew.rawValue,
            handler: { [weak self] result in
                guard let msg = result?.object as? Message else {
                    return
                }
                guard let recordMessages = self?.recordMessages else {
                    return
                }
                for m in recordMessages {
                    if m.msgId == msg.msgId {
                        self?.messageLayout.insertMessage(msg)
                    }
                }
            })
        SwiftEventBus.onMainThread(
            self, name: IMEvent.MsgUpdate.rawValue,
            handler: { [weak self] result in
                guard let msg = result?.object as? Message else {
                    return
                }
                guard let recordMessages = self?.recordMessages else {
                    return
                }
                for m in recordMessages {
                    if m.msgId == msg.msgId {
                        self?.messageLayout.insertMessage(msg)
                    }
                }
            })
    }

    func previewMessage(_ msg: Message, _ position: Int, _ originView: UIView) {
        let intercepted = IMUIManager.shared.getMsgCellProvider(msg.type).onMsgContentClick(
            self, msg, self.session, originView)
        if !intercepted {
            if msg.type == MsgType.Image.rawValue || msg.type == MsgType.Video.rawValue {
                if let messages = self.recordMessages {
                    let mediaMessages = messages.filter { m in
                        return m.type == MsgType.Image.rawValue
                            || msg.type == MsgType.Video.rawValue
                    }
                    IMUIManager.shared.contentPreviewer?.previewMessage(
                        self, mediaMessages, originView, false, msg.msgId)
                }
            } else if msg.type == MsgType.Record.rawValue {
                IMUIManager.shared.contentPreviewer?.previewRecordMessage(self, originSession!, msg)
            }
        }
    }

}

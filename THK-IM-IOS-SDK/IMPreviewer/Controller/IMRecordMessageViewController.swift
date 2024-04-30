//
//  IMRecordMessageViewController.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/26.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class IMRecordMessageViewController: BaseViewController, IMMsgPreviewer {
    
    var recordTitle: String? = nil
    var recordMessages: Array<Message>? = nil
    var originSession: Session? = nil
    var session: Session? = nil
    private var messageLayout = IMMessageLayout()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = IMUIManager.shared.uiResourceProvider?.inputBgColor()
        if let title = self.recordTitle {
            self.navigationItem.title = title
        }
        
        self.messageLayout.session = session
        self.messageLayout.mode = 1
        self.messageLayout.previewer = self
        self.view.addSubview(messageLayout)
        if let messages = self.recordMessages {
            self.messageLayout.addMessages(messages)
        }
        self.initEvent()
        messageLayout.snp.makeConstraints { make in
            make.edges.equalToSuperview()
        }
    }
    
    private func initEvent() {
        SwiftEventBus.onMainThread(self, name: IMEvent.MsgNew.rawValue, handler: { [weak self ] result in
            guard let msg = result?.object as? Message else {
                return
            }
            guard let recordMessages = self?.recordMessages else {
                return
            }
            for m in recordMessages {
                if (m.msgId == msg.msgId) {
                    self?.messageLayout.insertMessage(msg)
                }
            }
        })
        SwiftEventBus.onMainThread(self, name: IMEvent.MsgUpdate.rawValue, handler: { [weak self ]result in
            guard let msg = result?.object as? Message else {
                return
            }
            guard let recordMessages = self?.recordMessages else {
                return
            }
            for m in recordMessages {
                if (m.msgId == msg.msgId) {
                    self?.messageLayout.insertMessage(msg)
                }
            }
        })
    }
    
    
    func previewMessage(_ msg: Message, _ position: Int, _ originView: UIView) {
        if msg.type == MsgType.Image.rawValue || msg.type == MsgType.Video.rawValue {
            IMUIManager.shared.contentPreviewer?.previewMessage(self, [msg], originView, msg.msgId)
        } else if (msg.type == MsgType.Record.rawValue) {
            IMUIManager.shared.contentPreviewer?.previewRecordMessage(self, originSession! , msg)
        }
    }
    
}

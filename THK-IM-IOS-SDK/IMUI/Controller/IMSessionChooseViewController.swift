//
//  SessionChoosePopView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/25.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import RxSwift
import UIKit

open class IMSessionChooseViewController: IMSessionViewController {

    var forwardType: Int?
    var messages: [Message]?
    weak var sender: IMMsgSender?

    public static func popup(
        vc: UIViewController, forwardType: Int, messages: [Message], sender: IMMsgSender
    ) {
        let choose = IMSessionChooseViewController()
        choose.forwardType = forwardType
        choose.messages = messages
        choose.sender = sender
        let transition = CATransition.init()
        transition.duration = 0.4
        transition.type = .moveIn
        transition.subtype = .fromTop
        vc.navigationController?.view.layer.add(transition, forKey: kCATransition)
        vc.navigationController?.pushViewController(choose, animated: false)
    }
    
    open override func title() -> String? {
        return ResourceUtils.loadString("choose_one_session")
    }
    
    open override func viewDidLoad() {
        super.viewDidLoad()
        self.view.backgroundColor = IMUIManager.shared.uiResourceProvider?
            .layoutBgColor() ?? UIColor.init(hex: "#F2F2F2")
    }

    open override func openSession(_ session: Session) {
        guard let forwardType = self.forwardType else {
            return
        }
        guard let messages = self.messages else {
            return
        }
        if forwardType == 0 {  // 单条转发
            for m in messages {
                IMCoreManager.shared.messageModule.getMsgProcessor(m.type)
                    .forwardMessage(m, session.id)
            }
            self.pop()
        } else {  // 转发历史记录
            self.buildRecordBody(messages: messages, session: session)
                .compose(RxTransformer.shared.io2Main())
                .subscribe(
                    onNext: { recordBody in
                        let newBody = recordBody.clone()
                        for m in newBody.messages {
                            m.operateStatus =
                                MsgOperateStatus.Ack.rawValue | MsgOperateStatus.ClientRead.rawValue
                                | MsgOperateStatus.ServerRead.rawValue
                            m.sendStatus = MsgSendStatus.Success.rawValue
                            m.rUsers = nil
                            m.data = nil
                        }
                        IMCoreManager.shared.messageModule.sendMessage(
                            session.id, MsgType.Record.rawValue, newBody, nil, nil, nil, nil)
                    },
                    onCompleted: { [weak self] in
                        self?.pop()
                    }
                ).disposed(by: self.disposeBag)
        }
    }

    private func pop() {
        let transition = CATransition.init()
        transition.duration = 0.1
        transition.type = .reveal
        transition.subtype = .fromBottom
        transition.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        self.navigationController?.view.layer.add(transition, forKey: kCATransition)
        self.navigationController?.popViewController(animated: false)
    }

    private func buildRecordBody(messages: [Message], session: Session) -> Observable<
        IMRecordMsgBody
    > {
        let recordBody = IMRecordMsgBody(title: "", messages: messages, content: "")
        return Observable.just(recordBody)
            .flatMap({ [weak self] (recordBody) -> Observable<IMRecordMsgBody> in
                var content = ""
                var i = 0
                for m in messages {
                    var userName = "XX"
                    let member = self?.sender?.syncGetSessionMemberInfo(m.fromUId)
                    if member != nil {
                        if member?.0 != nil {
                            userName = member?.0.nickname ?? "XX"
                        }
                        if member?.1 != nil && member?.1?.noteName != "" {
                            userName = member?.1?.noteName ?? "XX"
                        }
                    }
                    let subContent = IMCoreManager.shared.messageModule.getMsgProcessor(m.type)
                        .msgDesc(msg: m)
                    content = "\(content)\(userName):\(subContent)"
                    if i > 5 {
                        break
                    }
                    i += 1
                    if i <= messages.count - 1 {
                        content += "\n"
                    }
                }
                recordBody.content = content
                return Observable.just(recordBody)
            }).flatMap({ [weak self] (recordBody) -> Observable<IMRecordMsgBody> in
                var userName = "XX"
                let member = self?.sender?.syncGetSessionMemberInfo(IMCoreManager.shared.uId)
                if member != nil {
                    if member?.0 != nil {
                        userName = member?.0.nickname ?? "XX"
                    }
                    if member?.1 != nil && member?.1?.noteName != "" {
                        userName = member?.1?.noteName ?? "XX"
                    }
                }
                recordBody.title = userName
                return Observable.just(recordBody)
            }).flatMap({ (recordBody) -> Observable<IMRecordMsgBody> in
                let title: String =
                    (session.type == SessionType.Group.rawValue
                        || session.type == SessionType.SuperGroup.rawValue)
                    ? ResourceUtils.loadString("someone_s_group_chat_record")
                    : ResourceUtils.loadString("someone_s_chat_record")
                recordBody.title = String.init(format: title, recordBody.title)
                return Observable.just(recordBody)
            })
    }

}

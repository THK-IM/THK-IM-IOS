//
//  SessionChoosePopView.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/25.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

class IMSessionChooseViewController: IMSessionViewController {
    
    var forwardType: Int?
    var messages: Array<Message>?
    let disposeBag = DisposeBag()
    
    public static func popup(vc: UIViewController, forwardType: Int, messages: Array<Message>) {
        let choose = IMSessionChooseViewController()
        choose.forwardType = forwardType
        choose.messages = messages
        let transition = CATransition.init()
        transition.duration = 0.4
        transition.type = .moveIn
        transition.subtype = .fromTop
        vc.navigationController?.view.layer.add(transition, forKey: kCATransition)
        vc.navigationController?.pushViewController(choose, animated: false)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        self.navigationItem.title = "选择一个聊天"
    }
    
    override func openSession(_ session: Session) {
        guard let forwardType = self.forwardType else {
            return
        }
        guard let messages = self.messages else {
            return
        }
        if (forwardType == 0) { // 单条转发
            for m in messages {
                IMCoreManager.shared.messageModule.getMsgProcessor(m.type)
                    .forwardMessage(m, session.id)
            }
            self.pop()
        } else { // 转发历史记录
            self.buildRecordBody(messages: messages, session: session)
                .compose(RxTransformer.shared.io2Main())
                .subscribe(onNext: { recordBody in
                    let newBody = recordBody.clone()
                    for m in newBody.messages {
                        m.operateStatus = MsgOperateStatus.Ack.rawValue | MsgOperateStatus.ClientRead.rawValue | MsgOperateStatus.ServerRead.rawValue
                        m.sendStatus = MsgSendStatus.Success.rawValue
                        m.rUsers = nil
                        m.data = nil
                    }
                    IMCoreManager.shared.messageModule.sendMessage(session.id, MsgType.Record.rawValue, newBody, nil, nil, nil, nil)
                }, onCompleted: { [weak self] in
                    self?.pop()
                }).disposed(by: self.disposeBag)
        }
    }
    
    private func pop() {
        let transition = CATransition.init()
        transition.duration = 0.4
        transition.type = .reveal
        transition.subtype = .fromBottom
        transition.timingFunction = CAMediaTimingFunction.init(name: .easeInEaseOut)
        self.navigationController?.view.layer.add(transition, forKey: kCATransition)
        self.navigationController?.popViewController(animated: false)
    }
    
    private func buildRecordBody(messages: Array<Message>, session: Session) -> Observable<IMRecordMsgBody> {
        var uIds = Set<Int64>()
        for m in messages {
            uIds.insert(m.fromUId)
        }
        return IMCoreManager.shared.userModule.queryUsers(ids: uIds).flatMap({ (userMap) -> Observable<IMRecordMsgBody> in
            var content = ""
            var i = 0
            for m in messages {
                let userName = userMap[m.fromUId]?.nickname ?? "XX"
                let subContent = IMCoreManager.shared.messageModule.getMsgProcessor(m.type).sessionDesc(msg: m)
                content = "\(content)\(userName):\(subContent)"
                i += 1
                if (i <= messages.count - 1) {
                    content += "\n"
                }
            }
            let recordBody = IMRecordMsgBody(title: "", messages: messages, content: content)
            
            return Observable.just(recordBody)
        }).flatMap({ (recordBody) -> Observable<IMRecordMsgBody> in
            let selfId = IMCoreManager.shared.uId
            return IMCoreManager.shared.userModule.queryUser(id: selfId).flatMap({ (user) ->  Observable<IMRecordMsgBody> in
                recordBody.title = user.nickname
                return Observable.just(recordBody)
            })
        }).flatMap({ (recordBody) -> Observable<IMRecordMsgBody> in
            let title: String = (session.type == SessionType.Group.rawValue) ? "的群聊记录" : "的聊天记录"
            recordBody.title = "\(recordBody.title)\(title)"
            return Observable.just(recordBody)
        })
    }
    
    
    
    
}

//
//  IMCustomModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/7.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import CocoaLumberjack
import RxSwift

public enum LiveSignalType: Int {
    case InviteLiveCall = 1,
         HangupLiveCall = 2,
         EndLiveCall = 3
}

public class LiveSignal: Codable {
    
    let roomId: String
    let members: Set<Int64>
    let ownerId: Int64
    let mode: Int
    let createTime: Int64
    let msgType: Int
    let operatorId: Int64
    
    enum CodingKeys: String, CodingKey {
        case roomId = "room_id"
        case members = "members"
        case ownerId = "owner_id"
        case mode = "mode"
        case createTime = "create_time"
        case msgType = "msg_type"
        case operatorId = "operator_id"
    }
    
    init(roomId: String, members: Set<Int64>, ownerId: Int64, mode: Int, createTime: Int64, msgType: Int, operatorId: Int64) {
        self.roomId = roomId
        self.members = members
        self.ownerId = ownerId
        self.mode = mode
        self.createTime = createTime
        self.msgType = msgType
        self.operatorId = operatorId
    }
}

class IMCustomModule: DefaultCustomModule {
    
    static let liveCallSignalType = 400
    
    private let disposeBag = DisposeBag()
    
    override func onSignalReceived(_ type: Int, _ body: String) {
        if type == IMCustomModule.liveCallSignalType {
            if let signal = try? JSONDecoder().decode(LiveSignal.self, from: body.data(using: .utf8) ?? Data()) {
                DDLogInfo("IMLiveManager: onSignalReceived \(signal)")
                let room = IMLiveManager.shared.getRoom()
                if signal.msgType == LiveSignalType.InviteLiveCall.rawValue {
                    if room != nil {
                        // TODO 拒绝
                    } else {
                        // TODO 弹出加入
                        if signal.ownerId != IMLiveManager.shared.selfId() {
                            IMLiveManager.shared.joinRoom(roomId: signal.roomId, role: Role.Broadcaster)
                                .compose(RxTransformer.shared.io2Main())
                                .subscribe(onNext: { room in
                                    let window = AppUtils.getWindow()
                                    let vc = window?.rootViewController
                                    if vc != nil {
                                        LiveCallViewController.presentLiveCallViewController(vc!, room)
                                    }
                                }).disposed(by: self.disposeBag)
                        }
                    }
                } else if signal.msgType == LiveSignalType.HangupLiveCall.rawValue {
                    if room != nil {
                        IMLiveManager.shared.onMemberHangup(roomId: signal.roomId, uId: signal.operatorId)
                    }
                } else if signal.msgType == LiveSignalType.EndLiveCall.rawValue {
                    if room != nil {
                        IMLiveManager.shared.onEndCall(roomId: signal.roomId)
                    }
                }
            }
        }
    }
    
}

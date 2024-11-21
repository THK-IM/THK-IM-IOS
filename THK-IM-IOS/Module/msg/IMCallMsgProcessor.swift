//
//  IMCallMsgProcessor.swift
//  THK-IM-IOS
//
//  Created by macmini on 2024/11/21.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

class IMCallMsgProcessor: IMBaseMsgProcessor {
    override func messageType() -> Int {
        return DemoMsgType.Call.rawValue
    }

    override func msgDesc(msg: Message) -> String {
        guard let d = msg.content?.data(using: .utf8) else { return "[语音通话]" }
        guard let callMsg = try? JSONDecoder().decode(IMCallMsg.self, from: d) else {
            return "[语音通话]"
        }
        if callMsg.roomMode == RoomMode.Audio.rawValue {
            return "[语音通话]"
        } else {
            return "[视频通话]"
        }
    }
}

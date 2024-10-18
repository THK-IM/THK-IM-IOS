//
//  IMUIDefines.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/2.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit

public enum IMMsgPosType: Int {
    case Mid = 0
    case
        Left = 1
    case
        Right = 2
}

public class IMFile {
    var data: Data
    var mimeType: String
    var name: String

    public init(data: Data, name: String, mimeType: String) {
        self.data = data
        self.mimeType = mimeType
        self.name = name
    }
}

/// 功能，1基础功能 2语音 4 表情  8 图片 16视频  32转发 64已读
public enum IMChatFunction: Int64 {
    case BaseInput = 1
    case
        Audio = 2
    case
        Emoji = 4
    case
        Image = 8
    case
        Video = 16
    case
        Forward = 32
    case
        Read = 64
    case
        ALL = 127
}

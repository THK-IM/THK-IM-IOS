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
    case Mid = 0,
         Left = 1,
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

/**
 功能，1基础功能 2语音 4 表情  8 图片 16视频  32转发 64已读
 */
public enum IMChatFunction: Int64 {
    case BaseInput = 1, // 文本输入/删除/文本表情
         Audio = 2,
        Emoji = 4,      //
        Image = 8,
        Video = 16,
        Forward = 32,
        Read = 64
}

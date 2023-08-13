//
//  MsgType.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/27.
//

import Foundation

public enum MsgType : Int {
    case UnSupport = 0, // 未知
         TEXT = 1,      // 文本
         EMOJI = 2,     // 表情图片
         Audio = 3,     // 语音
         IMAGE = 4,     // 图片
         RICH  = 5,     // 富文本
         VIDEO = 6,     // 视频
         FILE = 7,      // 文件
         LOCATION = 8,  // 定位
         CALL = 9       // 通话
}

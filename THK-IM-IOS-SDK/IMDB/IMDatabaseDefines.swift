//
//  IMDatabaseDefines.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/22.
//

import Foundation

/**
 * 会话类型
 */
public enum SessionType: Int {
    case Single = 1,
         Group = 2,
         SuperGroup = 3
}

/**
 * session 禁言
 */
public enum SessionMuted: Int {
    case Normal = 0,
         All = 1,
         MySelf = 2
}

/**
 * session  消息提示
 */
public enum SessionPrompt: Int {
    case Normal = 0,
         Reject = 1,
         Silent = 2
        
}

/**
 * 消息发送状态
 */
public enum MsgSendStatus: Int {
    case Init = 0,
         Uploading = 1,
         Sending = 2,
         Failed = 3,
         Success = 4
}

/**
 * 消息操作状态
 */
public enum MsgOperateStatus: Int {
    case Init = 0,
         Ack = 1,        // 用户已接收
         ClientRead = 2, // 用户已读
         ServerRead = 4, // 用户已告知服务端已读
         Revoke = 8,     // 用户撤回
         Update = 16     // 用户更新消息（重新编辑等操作）
}

/**
 * 消息类型
 */
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

/**
 * 性别
 */
public enum SexType: Int {
    case Unknown = 0,
         Man = 1,
         Women = 2,
         Machine = 3,
         Ai = 4
}
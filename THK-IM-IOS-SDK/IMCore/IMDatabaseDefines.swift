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
         SuperGroup = 3,
         MsgRecord = 0
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

public enum SessionRole: Int {
    case member = 1,
         admin = 2,
         superAdmin = 3,
         owner = 4
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
         Update = 8      // 用户更新消息（重新编辑等操作）
}

/**
 * 消息类型
 */
public enum MsgType : Int {
    case Reedit = -3,       // 重编辑消息
         Read = -2,         // 读取消息
         Received = -1,          // 收到消息
         UnSupport = 0,     // 未知
         Text = 1,          // 文本
         Emoji = 2,         // 表情图片
         Audio = 3,         // 语音
         Image = 4,         // 图片
         RichText  = 5,         // 富文本
         Video = 6,         // 视频
         Record = 7,        // 消息记录
         Revoke = 100,      // 撤回消息
         TimeLine = 9999    // 时间线消息
}

/**
 * 性别
 */
public enum SexType: Int8 {
    case Unknown = 0,
         Man = 1,
         Women = 2,
         Machine = 3,
         Ai = 4
}

/**
 * 用户状态
 */
public enum UserStatus: Int {
    case Normal = 0,
        Deleted = 1
}

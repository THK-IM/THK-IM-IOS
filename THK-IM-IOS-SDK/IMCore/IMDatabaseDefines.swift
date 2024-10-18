//
//  IMDatabaseDefines.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/22.
//

import Foundation

/// 会话类型
public enum SessionType: Int {
    case Single = 1
    case
        Group = 2
    case
        SuperGroup = 3
    case
        MsgRecord = 0
}

/// session 禁言
public enum SessionMuted: Int {
    case Normal = 0
    case
        All = 1
    case
        MySelf = 2
}

/// session  消息提示
public enum SessionPrompt: Int {
    case Normal = 0
    case
        Reject = 1
    case
        Silent = 2

}

public enum SessionRole: Int {
    case member = 1
    case
        admin = 2
    case
        superAdmin = 3
    case
        owner = 4
}

/// 消息发送状态
public enum MsgSendStatus: Int {
    case Init = 0
    case
        Uploading = 1
    case
        Sending = 2
    case
        Failed = 3
    case
        Success = 4
}

/// 消息操作状态
public enum MsgOperateStatus: Int {
    case Init = 0
    case
        Ack = 1
    case
        ClientRead = 2
    case
        ServerRead = 4
    case
        Update = 8  // 用户更新消息（重新编辑等操作）
}

/// 消息类型
public enum MsgType: Int {
    case Reedit = -3
    case
        Read = -2
    case
        Received = -1
    case
        UnSupport = 0
    case
        Text = 1
    case
        Emoji = 2
    case
        Audio = 3
    case
        Image = 4
    case
        RichText = 5
    case
        Video = 6
    case
        Record = 7
    case
        Revoke = 100
    case
        TimeLine = 9999  // 时间线消息
}

/// 性别
public enum SexType: Int8 {
    case Unknown = 0
    case
        Man = 1
    case
        Women = 2
    case
        Machine = 3
    case
        Ai = 4
}

/// 用户状态
public enum UserStatus: Int {
    case Normal = 0
    case
        Deleted = 1
}

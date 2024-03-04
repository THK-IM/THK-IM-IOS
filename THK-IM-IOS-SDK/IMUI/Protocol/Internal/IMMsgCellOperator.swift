//
//  IMMsgCellOperator.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/2.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit
import RxSwift

public protocol IMMsgCellOperator: AnyObject {
    
    /// 点击消息回复内容
    func onMsgReferContentClick(message: Message, view: UIView)
    
    /// 点击消息内容
    func onMsgCellClick(message: Message, position:Int, view: UIView)
    
    /// 点击消息发送人
    func onMsgSenderClick(message: Message, position: Int, view: UIView)
    
    /// 长按消息发送人
    func onMsgSenderLongClick(message: Message, position: Int, view: UIView)
    
    /// 长按消息
    func onMsgCellLongClick(message: Message, position:Int, view: UIView)
    
    /// 点击消息已读状态
    func onMsgReadStatusClick(message: Message)
    
    /// 点击消息重发
    func onMsgResendClick(message: Message)
    
    /// 是否为选择模式
    func isSelectMode() ->Bool
    
    /// 是否为被选中
    func isItemSelected(message: Message) ->Bool
    
    /// 选中
    func onSelected(message: Message, selected: Bool)
    
    /// 已读消息
    func readMessage(_ message: Message)
    
    /// 设置输入框文字
    func setEditText(text: String)
    
    /// 同步获取用户信息
    func syncGetSessionMemberInfo(_ userId: Int64) -> (User, SessionMember?)?
    
    /// 设置用户信息
    func saveSessionMemberInfo(_ info: (User, SessionMember?))
    
    /// 异步获取用户信息
    func asyncGetSessionMemberInfo(_ userId: Int64) -> Observable<(User, SessionMember?)>
}

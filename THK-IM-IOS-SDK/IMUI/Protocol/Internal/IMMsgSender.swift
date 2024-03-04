//
//  IMMsgSender.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/4.
//

import Foundation
import UIKit
import RxSwift

public protocol IMMsgSender : AnyObject {
    
    /// 获取视图控制器
    func viewController() -> UIViewController
    
    /// 获取session信息
    func getSession() -> Session?
    
    /// 重发消息
    func resendMessage(_ msg: Message)
    
    /// 发送消息
    func sendMessage(_ type: Int, _ body: Codable?, _ data: Codable?, _ atUsers: String?)
    
    /// 发送输入框内容
    func sendInputContent()
    
    /// 输入框添加内容
    func addInputContent(text: String)
    
    /// 删除输入框内容
    func deleteInputContent(count: Int)
    
    /// 选择照片
    func choosePhoto()
    
    /// 相机拍照
    func openCamera()
    
    /// 移动到最新消息
    func moveToLatestMessage()
    
    /// 打开底部面本:position: 1表情 2更多
    func showBottomPanel(_ position: Int)
    
    /// 关闭底部面板
    func closeBottomPanel()
    
    /// 顶起常驻视图（消息列表+底部输入框）
    func moveUpAlwaysShowView(_ isKeyboardShow: Bool, _ height: CGFloat, _ duration: Double)
    
    /// 打开键盘
    @discardableResult func openKeyboard() -> Bool
    
    /// 键盘是否显示
    func isKeyboardShowing() -> Bool
    
    /// 关闭键盘
    func closeKeyboard() -> Bool
    
    /// 打开/关闭多选消息视图
    func setSelectMode(_ selected: Bool, message: Message?)

    /// 删除多选视图选中的消息
    func deleteSelectedMessages()
    
    /// 设置已读消息
    func readMessage(_ message: Message)
    
    /// 弹出消息操作面板弹窗
    func popupMessageOperatorPanel(_ view: UIView, _ message: Message)
    
    /// show loading
    func showSenderLoading(text: String)

    /// dismiss Loading
    func dismissSenderLoading()

    /// show message
    func showSenderMessage(text: String, success: Bool)

    /// 发送消息到session forwardType 0单条转发, 1合并转发
    func forwardMessageToSession(messages: Array<Message>, forwardType: Int)

    /// 转发选定的消息 forwardType 0单条转发, 1合并转发
    func forwardSelectedMessages(forwardType: Int)
    
    ///  打开at会话成员控制器
    func openAtViewController()
    
    ///  添加at会话
    func addAtUser(user: User, sessionMember: SessionMember?)
    
    /// 回复消息
    func replyMessage(msg: Message)
    
    /// 关闭回复消息
    func closeReplyMessage()
    
    /// 重编辑消息
    func reeditMessage(_ message: Message)
    
    /// 同步获取用户信息
    func syncGetSessionMemberInfo(_ userId: Int64) -> (User, SessionMember?)?
    
    /// 设置用户信息
    func saveSessionMemberInfo(_ info: (User, SessionMember?))
    
    /// 异步获取用户信息
    func asyncGetSessionMemberInfo(_ userId: Int64) -> Observable<(User, SessionMember?)>
}

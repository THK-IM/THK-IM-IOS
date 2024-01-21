//
//  MsgSender.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/4.
//

import Foundation
import UIKit

public protocol IMMsgSender : AnyObject {
    
    /// 获取session信息
    func getSession() -> Session?
    
    /// 重发消息
    func resendMessage(_ msg: Message)
    
    /// 发送消息
    func sendMessage(_ type: Int, _ body: Codable?, _ data: Codable?, _ atUsers: String?, _ referMsgId: Int64?)
    
    /// 发送输入框内容
    func sendInputContent()
    
    /// 输入框添加内容
    func addInputContent(text: String, user: User?, sessionMember: SessionMember?)
    
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
    func openKeyboard() -> Bool
    
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
    func showLoading(text: String)

    /// dismiss Loading
    func dismissLoading()

    /// show message
    func showMessage(text: String, success: Bool)

    /// 发送消息到session forwardType 0单条转发, 1合并转发
    func forwardMessageToSession(messages: Array<Message>, forwardType: Int)

    /// 转发选定的消息 forwardType 0单条转发, 1合并转发
    func forwardSelectedMessages(forwardType: Int)
    
    ///  打开at会话成员控制器
    func openAtViewController()
}

//
//  MsgSender.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/4.
//

import Foundation

public protocol IMMsgSender : AnyObject {
    
    /// 获取session信息
    func getSession() -> Session?
    
    /// 重发消息
    func resendMessage(_ msg: Message)
    
    /// 发送消息
    func sendMessage(_ type: Int, _ body: Codable)
    
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
    func openKeyboard() -> Bool
    
    /// 键盘是否显示
    func isKeyboardShowing() -> Bool
    
    /// 关闭键盘
    func closeKeyboard() -> Bool
    
    /// 显示消息多选视图
    func showMsgSelectedLayout()
    
    /// 关闭消息多选视图
    func dismissMsgSelectedLayout()
}

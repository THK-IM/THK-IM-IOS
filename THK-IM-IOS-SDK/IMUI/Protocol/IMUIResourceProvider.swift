//
//  IMUIResourceProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/3/13.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import UIKit

public protocol IMUIResourceProvider {

    /// 头像
    func avatar(user: User) -> UIImage?

    /// 表情字符串数组
    func unicodeEmojis() -> [String]?

    /// 消息气泡图
    func msgBubble(message: Message, session: Session?) -> UIImage?

    /// 主题色
    func tintColor() -> UIColor?
    
    /// 底部输入，表情/更多/弹出面板背景颜色
    func panelBgColor() -> UIColor?

    /// 输入区域背景颜色
    func inputBgColor() -> UIColor?

    /// 页面背景颜色+文本输入位置背景颜色
    func layoutBgColor() -> UIColor?

    /// 输入文字颜色
    func inputTextColor() -> UIColor?

    /// 界面提示文字颜色
    func tipTextColor() -> UIColor?

    /// 是否支持某个功能
    func supportFunction(_ session: Session, _ functionFlag: Int64) -> Bool

    /// 是否可以At所有人
    func canAtAll(_ session: Session) -> Bool

}

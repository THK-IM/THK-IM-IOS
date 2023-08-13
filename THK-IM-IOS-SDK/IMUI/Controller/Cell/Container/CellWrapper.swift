//
//  CellWrapper.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/6/6.
//

import UIKit

class CellWrapper  {
    
    // cellWrapper类型 单聊/群聊,不同的类型有细微差别，如单聊不显示昵称
    let type: Int
    
    init(type: Int) {
        self.type = type
    }
    
    /**
     视图附着
     */
    open func attach(_ contentView: UIView) {
        
    }
    
    /**
     内容视图
     */
    open func containerView() -> UIView {
        return UIView()
    }
    
    /**
     消息状态视图
     */
    open func avatarView() -> UIImageView? {
        return nil
    }
    
    /**
     昵称视图
     */
    open func nickView() -> UILabel? {
        return nil
    }
    
    /**
     消息状态视图
     */
    open func statusView() -> UIView? {
        return nil
    }
    
    /**
     重发按钮
     */
    open func resendButton() -> UIButton? {
        return nil
    }
    
    
    /**
     已读状态视图
     */
    open func readStatusView() -> UIView? {
        return nil
    }
    
    
    open func appear() {
        
    }
    
    open func disAppear() {
        
    }
}

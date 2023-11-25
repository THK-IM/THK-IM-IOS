//
//  UserModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/18.
//

import Foundation
import RxSwift

public protocol UserModule : BaseModule {
    
    /// 用户信息更新
    func onUserInfoUpdate(user: User)
    
    /// 获取用户聊天气泡框
    func getUserChatBubble(id: Int64) -> Observable<UIImage>
    
    /// 获取用户信息
    func getUserInfo(id: Int64) -> Observable<User>
    
    /// 获取用户信息
    func getUserInfo(ids: Set<Int64>) -> Observable<Dictionary<Int64, User>>
    
}

//
//  UserModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/18.
//

import Foundation
import RxSwift

public protocol UserModule: BaseModule {

    func queryServerUser(id: Int64) -> Observable<User>

    /// 获取用户信息
    func queryUser(id: Int64) -> Observable<User>

    /// 获取用户信息
    func queryUsers(ids: Set<Int64>) -> Observable<[Int64: User]>

    /// 用户信息更新
    func onUserInfoUpdate(user: User)

}

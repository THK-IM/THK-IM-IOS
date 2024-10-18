//
//  UserDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/18.
//

import Foundation
import WCDBSwift

public protocol UserDao {

    /**
     * 插入用户信息
     */
    func insertOrReplace(_ users: [User]) throws

    /**
     * 插入用户信息
     */
    func insertOrIgnore(_ users: [User]) throws

    func delete(_ user: User) throws

    /**
     * 查询用户信息
     */
    func findById(_ id: Int64) -> User?

    func findByIds(_ ids: Set<Int64>) -> [User]?

}

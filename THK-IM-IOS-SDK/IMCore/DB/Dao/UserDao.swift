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
    func insertUsers(_ users: User...) throws
    
    /**
     * 查询用户信息
     */
    func queryUserInfo(_ id: Int64) throws -> User?
    
}

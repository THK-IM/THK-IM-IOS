//
//  UserDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/18.
//

import Foundation
import WCDBSwift

protocol UserDao {
    func insertUsers(_ users: User...) throws
    func queryUserInfo(_ id: Int64) throws -> User?
}

class innerUserDao : UserDao {
    
    weak var database: Database?
    let tableName: String
    
    init(_ database: Database, _ tableName: String) {
        self.database = database
        self.tableName = tableName
    }
    
    func insertUsers(_ users: User...) throws {
        try self.database?.insertOrReplace(users, intoTable: self.tableName)
    }
    
    func queryUserInfo(_ id: Int64) throws -> User? {
        return try self.database?.getObject(fromTable: self.tableName, where: User.Properties.id == id)
    }
    
}

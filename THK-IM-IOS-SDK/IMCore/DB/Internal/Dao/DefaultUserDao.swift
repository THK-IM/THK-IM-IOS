//
//  DefaultUserDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/8/22.
//

import Foundation
import WCDBSwift

open class DefaultUserDao: UserDao {

    weak var database: Database?
    let tableName: String

    init(_ database: Database, _ tableName: String) {
        self.database = database
        self.tableName = tableName
    }

    public func insertOrReplace(_ users: [User]) throws {
        try self.database?.insertOrReplace(users, intoTable: self.tableName)
    }

    public func insertOrIgnore(_ users: [User]) throws {
        try self.database?.insertOrIgnore(users, intoTable: self.tableName)
    }

    public func delete(_ user: User) throws {
        try self.database?.delete(
            fromTable: self.tableName,
            where: User.Properties.id == user.id
        )
    }

    public func findById(_ id: Int64) -> User? {
        return try? self.database?.getObject(
            fromTable: self.tableName, where: User.Properties.id == id)
    }

    public func findByIds(_ ids: Set<Int64>) -> [User]? {
        var uIds = [Int64]()
        for id in ids {
            uIds.append(id)
        }
        return try? self.database?.getObjects(
            fromTable: self.tableName, where: User.Properties.id.in(uIds))
    }

}

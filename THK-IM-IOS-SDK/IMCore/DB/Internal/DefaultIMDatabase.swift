//
//  DefaultIMDatabase.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/26.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation
import UIKit
import WCDBSwift
import CocoaLumberjack

class DefaultIMDatabase: IMDatabase {
    
    private weak var app: UIApplication?
    private let database: Database
    private let messageDaoImp: MessageDao
    private let sessionDaoImp: SessionDao
    private let userDaoImp: UserDao
    
    public init(_ app: UIApplication, _ uId: Int64, _ debug: Bool) {
        self.app = app
        
        let env = debug ? "debug" : "release"
        let documentPath = NSHomeDirectory() + "/Documents/im"
        let filePath = String(format: "%@/%d-%@.db", arguments: [documentPath, uId, env])
        self.database = Database(at: filePath)
    
        do {
            try self.database.create(table: TableName.User.rawValue, of: User.self)
            try self.database.create(table: TableName.Message.rawValue, of: Message.self)
            try self.database.create(table: TableName.Session.rawValue, of: Session.self)
        } catch {
            DDLogError(error)
        }
        
        self.messageDaoImp = DefaultMessageDao(self.database, TableName.Message.rawValue)
        self.sessionDaoImp = DefaultSessionDao(self.database, TableName.Session.rawValue)
        self.userDaoImp = DefaultUserDao(self.database, TableName.User.rawValue)
    }
    
    
    public func open() {
        try? self.messageDao().resetSendStatusFailed()
    }
    
    public func close() {
        self.database.close()
    }
    
    public func messageDao() -> MessageDao {
        return self.messageDaoImp
    }
    
    public func userDao() -> UserDao {
        return self.userDaoImp
    }
    
    public func sessionDao() -> SessionDao {
        return self.sessionDaoImp
    }
}

//
//  THK-IM-IOSDatabase.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/13.
//

import Foundation
import WCDBSwift
import UIKit
import CocoaLumberjack

class IMDatabase {
    
    private weak var app: UIApplication?
    private let database: Database
    public let messageDao: MessageDao
    public let sessionDao: SessionDao
    public let userDao: UserDao
    
    init(_ app: UIApplication, _ uId: Int64, _ debug: Bool) {
        self.app = app;
        let env = debug ? "debug" : "release"
        let documentPath = NSHomeDirectory() + "/Documents/im"
        DDLogDebug("documentPath: " + documentPath.description)
        let filePath = String(format: "%@/%d-%@.db", arguments: [documentPath, uId, env])
        self.database = Database(at: filePath)
        
        do {
            try self.database.create(table: TableName.User.rawValue, of: User.self)
            try self.database.create(table: TableName.Message.rawValue, of: Message.self)
            try self.database.create(table: TableName.Session.rawValue, of: Session.self)
        } catch {
            DDLogError(error)
        }
        
        self.messageDao = DefaultMessageDao(self.database, TableName.Message.rawValue)
        self.sessionDao = DefaultSessionDao(self.database, TableName.Session.rawValue)
        self.userDao = DefaultUserDao(self.database, TableName.User.rawValue)
    }
}

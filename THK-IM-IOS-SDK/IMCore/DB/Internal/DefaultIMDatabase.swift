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
    
    private let database: Database
    private let messageDaoImp: MessageDao
    private let sessionDaoImp: SessionDao
    private let userDaoImp: UserDao
    private let contactDaoImp: ContactDao
    private let groupDaoImp: GroupDao
    private let sessionMemberDaoImp: SessionMemberDao
    private let version = 1
    
    public init(_ uId: Int64, _ debug: Bool) {
        let dbFilePath = DefaultIMDatabase.dbFilePath(uId, debug, version)
        self.database = Database(at: dbFilePath)
        do {
            try self.database.create(table: TableName.User.rawValue, of: User.self)
            try self.database.create(table: TableName.Contact.rawValue, of: Contact.self)
            try self.database.create(table: TableName.Group.rawValue, of: Group.self)
            try self.database.create(table: TableName.SessionMember.rawValue, of: SessionMember.self)
            try self.database.create(table: TableName.Message.rawValue, of: Message.self)
            try self.database.create(table: TableName.Session.rawValue, of: Session.self)
        } catch {
            DDLogDebug("\(error)")
        }
        self.messageDaoImp = DefaultMessageDao(self.database, TableName.Message.rawValue)
        self.sessionDaoImp = DefaultSessionDao(self.database, TableName.Session.rawValue)
        self.userDaoImp = DefaultUserDao(self.database, TableName.User.rawValue)
        self.contactDaoImp = DefaultContactDao(self.database, TableName.Contact.rawValue)
        self.groupDaoImp = DefaultGroupDao(self.database, TableName.Group.rawValue)
        self.sessionMemberDaoImp = DefaultSessionMemberDao(self.database, TableName.SessionMember.rawValue)
        
        self.migrate(uId, debug)
    }
    
    private static func dbFilePath(_ uId: Int64, _ debug: Bool, _ v: Int) -> String {
        let env = debug ? "Debug" : "Release"
        let documentPath = NSHomeDirectory() + "/Documents/THKIM"
        let filePath = "\(documentPath)/DB_\(uId)_\(env)_\(v).db"
        return filePath
    }
    
    private func oldDbFile(_ uId: Int64, _ debug: Bool) -> String? {
        var oldVersion = self.version - 1
        while oldVersion > 0 {
            let oldDbFilePath = DefaultIMDatabase.dbFilePath(uId, debug, oldVersion)
            if FileManager.default.fileExists(atPath: oldDbFilePath) {
                return oldDbFilePath
            }
            oldVersion -= 1
        }
        return nil
    }
    
    private func migrate(_ uId: Int64, _ debug: Bool) {
        if let oldDbFile = self.oldDbFile(uId, debug) {
            self.database.filterMigration { info in
                info.sourceDatabase = oldDbFile
                info.sourceTable = info.table
            }
            while (!self.database.isMigrated()) {
                try? self.database.stepMigration()
            }
        }
    }
    
    public func open() {
        let sendingMessage = messageDaoImp.findSendingMessages(successStatus: MsgSendStatus.Success.rawValue)
        if !sendingMessage.isEmpty {
            do {
                try messageDaoImp.resetSendStatusFailed()
                for m in sendingMessage {
                    m.sendStatus = MsgSendStatus.Failed.rawValue
                    IMCoreManager.shared.messageModule.processSessionByMessage(m, false)
                }
            } catch {
                DDLogError("resetSendStatusFailed: \(error)")
            }
        }
    }
    
    public func close() {
        if (self.database.isOpened) {
            self.database.close()
        }
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
    
    func sessionMemberDao() -> SessionMemberDao {
        return self.sessionMemberDaoImp
    }
    
    func groupDao() -> GroupDao {
        return self.groupDaoImp
    }
    
    func contactDao() -> ContactDao {
        return self.contactDaoImp
    }
}

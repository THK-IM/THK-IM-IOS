//
//  THK-IM-IOSDatabase.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/13.
//

import CocoaLumberjack
import Foundation
import UIKit
import WCDBSwift

public protocol IMDatabase {

    func open()

    func close()

    func messageDao() -> MessageDao

    func userDao() -> UserDao

    func sessionDao() -> SessionDao

    func sessionMemberDao() -> SessionMemberDao

    func groupDao() -> GroupDao

    func contactDao() -> ContactDao

}

//
//  IMSessionMemberAtDelegate.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/20.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

public protocol IMSessionMemberAtDelegate: AnyObject {
    
    func onSessionMemberAt(_ memberInfo: (User, SessionMember?))
    
}

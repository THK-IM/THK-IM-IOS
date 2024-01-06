//
//  ContactDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

public protocol ContactDao {
    
    func insertOrReplace(_ contacts: Contact...) throws
    
    func insertOrIgnore(_ contacts: Contact...) throws
    
    func findByIds(_ ids: Set<Int64>) -> [Contact]?
    
}

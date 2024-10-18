//
//  ContactDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

public protocol ContactDao {

    func insertOrReplace(_ contacts: [Contact]) throws

    func insertOrIgnore(_ contacts: [Contact]) throws

    func findAll() -> [Contact]

    func findByUserId(_ contactId: Int64) -> Contact?

    func findByUserIds(_ ids: [Int64]) -> [Contact]

    func findByRelation(_ relation: Int) -> [Contact]

}

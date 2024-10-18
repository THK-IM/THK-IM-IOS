//
//  GroupDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

public protocol GroupDao {

    func insertOrReplace(_ groups: [Group]) throws

    func insertOrIgnore(_ groups: [Group]) throws

    func deleteByIds(_ ids: Set<Int64>) throws

    func findAll() -> [Group]

    func findById(_ id: Int64) -> Group?

}

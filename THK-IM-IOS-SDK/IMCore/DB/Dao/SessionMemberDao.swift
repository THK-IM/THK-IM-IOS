//
//  SessionMemberDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

public protocol SessionMemberDao {

    func insertOrReplace(_ members: [SessionMember]) throws

    func insertOrIgnore(_ members: [SessionMember]) throws

    func delete(_ members: [SessionMember]) throws

    func findSessionMember(_ sessionId: Int64, _ userId: Int64) -> SessionMember?
    
    func findSessionMembers(_ sessionId: Int64, _ userIds: Set<Int64>) -> [SessionMember]

    func findBySessionId(_ sessionId: Int64) -> [SessionMember]

    func findBySessionId(_ sessionId: Int64, _ offset: Int, _ count: Int) -> [SessionMember]
    
    func findBySessionIdSortByRole(_ sessionId: Int64, _ offset: Int, _ count: Int) -> [SessionMember]

    func findSessionMemberCount(_ sessionId: Int64) -> Int

}

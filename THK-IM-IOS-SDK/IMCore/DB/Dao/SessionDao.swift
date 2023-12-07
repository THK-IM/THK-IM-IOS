//
//  SessionDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/14.
//

import Foundation
import WCDBSwift

public protocol SessionDao {
    
    /**
     * 批量更新session
     */
    func updateSessions(_ sessions: Session...) throws
    
    /**
     * 批量插入session
     */
    func insertOrUpdateSessions(_ sessions: Session...) throws
    
    /**
     * 批量插入session
     */
    func insertOrIgnoreSessions(_ sessions: Session...) throws
    
    
    /**
     * 批量删除session
     */
    func deleteSessions(_ sessions: Session...) throws
    
    /**
     * 通过sessionId查询session
     */
    func findSessionById(_ sessionId: Int64) throws -> Session?
    
    /**
     * 通过对方id查询session
     */
    func findSessionByEntityId(_ entityId: Int64, _ type: Int) throws -> Session?
    
    /**
     * 查询mTim之后的session数组
     * @param parentId 父sessionId
     * @param count 数量
     * @param mTime 修改时间
     */
    func findSessions(_ parentId: Int64, _ count: Int, _ mTime: Int64) throws -> Array<Session>?
}

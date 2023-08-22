//
//  SessionDao.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/14.
//

import Foundation
import WCDBSwift

protocol SessionDao {
    
    /**
     * 批量更新session
     */
    func updateSessions(_ sessions: Session...) throws
    
    /**
     * 批量插入session
     */
    func insertSessions(_ sessions: Session...) throws
    
    /**
     * 通过sessionId查询session
     */
    func querySessionById(_ sessionId: Int64) throws -> Session?
    
    /**
     * 通过对方id查询session
     */
    func querySessionByEntityId(_ entityId: Int64, _ type: Int) throws -> Session?
    
    /**
     * 查询mTim之后的session数组
     * @param count 数量
     * @param mTime 修改时间
     */
    func querySessions(_ count: Int, _ mTime: Int64) throws -> Array<Session>?
}

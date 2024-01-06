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
     * 批量插入session
     */
    func insertOrUpdate(_ sessions: Session...) throws
    
    /**
     * 批量插入session
     */
    func insertOrIgnore(_ sessions: Session...) throws
    
    
    /**
     * 批量删除session
     */
    func delete(_ sessions: Session...) throws
    
    /**
     * 批量更新session
     */
    func update(_ sessions: Session...) throws
    
    /**
     * 通过sessionId查询session
     */
    func findById(_ sessionId: Int64) throws -> Session?
    
    /**
     * 通过对方id查询session
     */
    func findByEntityId(_ entityId: Int64, _ type: Int) throws -> Session?
    
    /**
     * 查询mTim之后的session数组
     * @param parentId 父sessionId
     * @param count 数量
     * @param mTime 修改时间
     */
    func findByParentId(_ parentId: Int64, _ count: Int, _ mTime: Int64) throws -> Array<Session>?
}

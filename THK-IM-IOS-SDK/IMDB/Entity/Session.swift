//
//  Message.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/14.
//

import Foundation
import WCDBSwift

public final class Session: TableCodable {
    var id: Int64 = 0
    var type: Int = 0
    var entityId : Int64 = 0
    var draft: Int64 = 0
    var lastMsg: String? = nil
    var status: Int? = 0
    var top: Int64? = 0
    var unRead: Int = 0
    var extData: String? = nil
    var cTime: Int64 = 0
    var mTime: Int64 = 0
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = Session
        public static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true)
            BindMultiUnique(type, entityId, onConflict: ConflictAction.Ignore)
            BindIndex(type, entityId, namedWith: "_session_entity_index", isUnique: true)
        }
        case id = "id"
        case type = "type"
        case entityId = "entity_id"
        case draft = "draft"
        case lastMsg = "last_msg"
        case status = "status"
        case top = "top"
        case unRead = "un_read"
        case extData = "ext_data"
        case cTime = "c_time"
        case mTime = "m_time"
    }
    
    public var isAutoIncrement: Bool = false // 用于定义是否使用自增的方式插入
}

//
//  Contact.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/6.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation
import WCDBSwift

public final class Contact: TableCodable {
    // 联系人id
    public var id: Int64
    // 会话id
    public var sessionId: Int64?
    public var noteName: String?
    public var relation: Int = 0
    public var extData: String?
    public var cTime: Int64
    public var mTime: Int64
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = Contact
        public static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true, onConflict: .Replace)
            BindIndex(sessionId, namedWith: "contact_session_idx", isUnique: false)
        }
        case id = "id"
        case sessionId = "session_id"
        case noteName = "note_name"
        case relation = "relation"
        case extData = "ext_data"
        case cTime = "c_time"
        case mTime = "m_time"
    }
    
    public var isAutoIncrement: Bool = false // 用于定义是否使用自增的方式插入
    
    public init(id: Int64, sessionId: Int64? = nil, noteName: String? = nil, relation: Int, extData: String? = nil, cTime: Int64, mTime: Int64) {
        self.id = id
        self.sessionId = sessionId
        self.noteName = noteName
        self.relation = relation
        self.extData = extData
        self.cTime = cTime
        self.mTime = mTime
    }
}

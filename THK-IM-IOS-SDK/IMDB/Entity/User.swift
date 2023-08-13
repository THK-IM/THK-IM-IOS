//
//  User.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/18.
//

import Foundation

import Foundation
import WCDBSwift

public final class User: TableCodable, Codable {
    var id: Int64 = 0
    var name: String = ""
    var avatar: String = ""
    var sex: Int = SexType.Unknown.rawValue
    var status: Int = 0
    var extData: String? = nil
    var cTime: Int64 = 0
    var mTime: Int64 = 0
    
    init(id: Int64, name: String, avatar: String, sex: Int, status: Int, extData: String? = nil, cTime: Int64, mTime: Int64) {
        self.id = id
        self.name = name
        self.avatar = avatar
        self.sex = sex
        self.status = status
        self.extData = extData
        self.cTime = cTime
        self.mTime = mTime
    }
    
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = User
        public static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true, onConflict: .Replace)
        }
        case id = "id"
        case name = "name"
        case avatar = "avatar"
        case sex="sex"
        case status="status"
        case extData = "ext_data"
        case cTime = "c_time"
        case mTime = "m_time"
    }
    
    public var isAutoIncrement: Bool = false // 用于定义是否使用自增的方式插入
}

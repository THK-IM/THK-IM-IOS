//
//  User.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/18.
//

import Foundation

import Foundation
import WCDBSwift

public final class User: TableCodable {
    // 用户id
    var id: Int64
    // 用户名称
    var name: String
    // 用户头像
    var avatar: String
    // 用户性别
    var sex: Int = SexType.Unknown.rawValue
    // 用户状态
    var status: Int = 0
    // 自定义扩展数据 推荐使用json结构存储
    var extData: String? = nil
    // 创建时间
    var cTime: Int64 = 0
    // 修改时间
    var mTime: Int64 = 0
    
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
}

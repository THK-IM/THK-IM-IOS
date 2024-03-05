//
//  User.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/18.
//

import WCDBSwift

public final class User: TableCodable {
    // 用户id
    public var id: Int64
    // 显示id
    public var displayId: String
    // 用户名称
    public var nickname: String
    // 用户头像
    public var avatar: String?
    // 用户性别
    public var sex: Int? = SexType.Unknown.rawValue
    // 用户状态
    public var status: Int = 0
    // 自定义扩展数据 推荐使用json结构存储
    public var extData: String? = nil
    // 创建时间
    public var cTime: Int64 = 0
    // 修改时间
    public var mTime: Int64 = 0
    
    public enum CodingKeys: String, CodingTableKey {
        public typealias Root = User
        public static let objectRelationalMapping = TableBinding(CodingKeys.self) {
            BindColumnConstraint(id, isPrimary: true, onConflict: .Replace)
        }
        case id = "id"
        case displayId = "display_id"
        case nickname = "nickname"
        case avatar = "avatar"
        case sex="sex"
        case status="status"
        case extData = "ext_data"
        case cTime = "c_time"
        case mTime = "m_time"
    }
    
    public var isAutoIncrement: Bool = false // 用于定义是否使用自增的方式插入
    
    public init(id: Int64, nickname: String = "") {
        self.id = id
        self.displayId = ""
        self.nickname = ""
        self.avatar = nil
        self.sex = nil
        self.status = 0
        self.extData = nil
        self.cTime = 0
        self.mTime = 0
    }
    
    public init(id: Int64, displayId: String, nickname: String, avatar: String?, sex: Int?, status: Int,
                extData: String? = nil, cTime: Int64, mTime: Int64)
    {
        self.id = id
        self.displayId = displayId
        self.nickname = nickname
        self.avatar = avatar
        self.sex = sex
        self.status = status
        self.extData = extData
        self.cTime = cTime
        self.mTime = mTime
    }
    
    public static let all = User(id: -1, nickname: "All")
}

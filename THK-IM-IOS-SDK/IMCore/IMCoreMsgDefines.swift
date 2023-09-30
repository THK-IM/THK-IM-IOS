//
//  IMCoreMsgDefines.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/9/2.
//

import Foundation

public class IMCommonMsgData: Codable {
    // 回复当前消息的消息id数组
    var replyMsgIds: Set<Int64>?
    // 已读用户
    var readUIds: Set<Int64>?
    
    enum CodingKeys: String, CodingKey {
        case replyMsgIds = "reply_msg_ids"
        case readUIds = "read_u_ids"
    }
    
    init() {}
    
    init(replyMsgIds: Set<Int64>? = nil, readUIds: Set<Int64>? = nil) {
        self.replyMsgIds = replyMsgIds
        self.readUIds = readUIds
    }
}

public class IMAudioMsgData: IMCommonMsgData {
    var path: String?
    var duration: Int?
    var played: Bool
    
    enum CodingKeys: String, CodingKey {
        case path = "path"
        case duration = "duration"
        case played = "played"
    }
    
    override init() {
        self.played = false
        super.init()
    }
    
    init(path: String? = nil, duration: Int? = nil, played: Bool = false) {
        self.path = path
        self.duration = duration
        self.played = played
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.path = try container.decode(String?.self, forKey: .path)
        self.duration = try container.decode(Int?.self, forKey: .duration)
        self.played = try container.decode(Bool.self, forKey: .played)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(path, forKey: .path)
        try container.encode(duration, forKey: .duration)
        try container.encode(played, forKey: .played)
        try super.encode(to: encoder)
    }
}

public class IMImageMsgData: IMCommonMsgData {
    var width: Int?
    var height: Int?
    var path: String?
    var thumbnailPath: String?
    
    enum CodingKeys: String, CodingKey {
        case width = "width"
        case height = "height"
        case path = "path"
        case thumbnailPath = "thumbnail_path"
    }
    
    override init() {
        super.init()
    }
    
    init(width: Int?, height: Int?, path: String? = nil, thumbnailPath: String? = nil) {
        self.width = width
        self.height = height
        self.path = path
        self.thumbnailPath = thumbnailPath
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.width = try container.decode(Int?.self, forKey: .width)
        self.height = try container.decode(Int?.self, forKey: .height)
        self.path = try container.decode(String?.self, forKey: .path)
        self.thumbnailPath = try container.decode(String?.self, forKey: .thumbnailPath)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(path, forKey: .path)
        try container.encode(thumbnailPath, forKey: .thumbnailPath)
        try super.encode(to: encoder)
    }
}

public class IMVideoMsgData: IMCommonMsgData {
    var duration: Int?
    var width: Int?
    var height: Int?
    var path: String?
    var thumbnailPath: String?
    
    enum CodingKeys: String, CodingKey {
        case duration = "duration"
        case width = "width"
        case height = "height"
        case path = "path"
        case thumbnailPath = "thumbnail_path"
    }
    
    override init() {
        super.init()
    }
    
    init(duration: Int?, width: Int?, height:Int?, path: String? = nil, thumbnailPath: String? = nil) {
        self.duration = duration
        self.width = duration
        self.height = height
        self.path = path
        self.thumbnailPath = thumbnailPath
        super.init()
    }
    
    public required init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        self.duration = try container.decode(Int?.self, forKey: .duration)
        self.width = try container.decode(Int?.self, forKey: .width)
        self.height = try container.decode(Int?.self, forKey: .height)
        self.path = try container.decode(String?.self, forKey: .path)
        self.thumbnailPath = try container.decode(String?.self, forKey: .thumbnailPath)
        try super.init(from: decoder)
    }
    
    public override func encode(to encoder: Encoder) throws {
        var container = encoder.container(keyedBy: CodingKeys.self)
        try container.encode(duration, forKey: .duration)
        try container.encode(width, forKey: .width)
        try container.encode(height, forKey: .height)
        try container.encode(path, forKey: .path)
        try container.encode(thumbnailPath, forKey: .thumbnailPath)
        try super.encode(to: encoder)
    }
}

public class IMAudioMsgBody: Codable {
    
    var duration: Int?
    var url: String?
    var name: String?
    
    enum CodingKeys: String, CodingKey {
        case duration = "duration"
        case url = "url"
        case name = "name"
    }
    
    init() {}
    
    init(duration: Int?, url: String?, name: String?) {
        self.duration = duration
        self.url = url
        self.name = name
    }
}

public class IMImageMsgBody: Codable {
    
    var width: Int?
    var height: Int?
    var thumbnailUrl: String?
    var url: String?
    var name: String?
    
    enum CodingKeys: String, CodingKey {
        case width = "width"
        case height = "height"
        case url = "url"
        case name = "name"
        case thumbnailUrl = "thumbnail_url"
    }
    
    init() {}
    
    init(width: Int?, height: Int?, thumbnailUrl: String?, url: String?, name: String?) {
        self.width = width
        self.height = height
        self.thumbnailUrl = thumbnailUrl
        self.url = url
        self.name = name
    }
}

public class IMVideoMsgBody: Codable {
    
    var duration: Int?
    var width: Int?
    var height: Int?
    var thumbnailUrl: String?
    var url: String?
    var name: String?
    
    enum CodingKeys: String, CodingKey {
        case duration = "duration"
        case width = "width"
        case height = "height"
        case url = "url"
        case thumbnailUrl = "thumbnail_url"
        case name = "name"
    }
    
    init() {}
    
    init(duration: Int?, width: Int?, height: Int?, thumbnailUrl: String?, url: String?, name: String?) {
        self.duration = duration
        self.width = width
        self.height = height
        self.thumbnailUrl = thumbnailUrl
        self.url = url
        self.name = name
    }
}


//
//  IMCoreMsgDefines.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/9/2.
//

import Foundation

public class IMAudioMsgData: Codable {
    var path: String?
    var duration: Int?
    var played: Bool
    
    enum CodingKeys: String, CodingKey {
        case path = "path"
        case duration = "duration"
        case played = "played"
    }
    
    public init() {
        self.played = false
    }
    
    public init(path: String? = nil, duration: Int? = nil, played: Bool = false) {
        self.path = path
        self.duration = duration
        self.played = played
    }
}

public class IMImageMsgData: Codable {
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
    
    public init() {
    }
    
    public init(width: Int?, height: Int?, path: String? = nil, thumbnailPath: String? = nil) {
        self.width = width
        self.height = height
        self.path = path
        self.thumbnailPath = thumbnailPath
    }
}

public class IMVideoMsgData: Codable {
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
    
    public init() {}
    
    public init(duration: Int?, width: Int?, height:Int?, path: String? = nil, thumbnailPath: String? = nil) {
        self.duration = duration
        self.width = duration
        self.height = height
        self.path = path
        self.thumbnailPath = thumbnailPath
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
    
    public init() {}
    
    public init(duration: Int?, url: String?, name: String?) {
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
    
    public init() {}
    
    public init(width: Int?, height: Int?, thumbnailUrl: String?, url: String?, name: String?) {
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
    
    public init() {}
    
    public init(duration: Int?, width: Int?, height: Int?, thumbnailUrl: String?, url: String?, name: String?) {
        self.duration = duration
        self.width = width
        self.height = height
        self.thumbnailUrl = thumbnailUrl
        self.url = url
        self.name = name
    }
}

public class IMRevokeMsgData: Codable {
    var nick: String
    var type: Int? = nil
    var content: String? = nil
    var data: String? = nil
    
    public init(nick: String, type: Int? = nil, content: String? = nil, data: String? = nil) {
        self.nick = nick
        self.type = type
        self.content = content
        self.data = data
    }
    
    enum CodingKeys: String, CodingKey {
        case nick = "nick"
        case type = "type"
        case content = "content"
        case data = "data"
    }
}


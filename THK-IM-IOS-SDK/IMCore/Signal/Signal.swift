//
//  Signal.swift
//  demo
//
//  Created by vizoss on 2023/5/20.
//

import Foundation

class Signal: Codable {
    var type : Int
    var subType: Int
    var body: String
    static var heatBeat : String {
        let signal = Signal(SignalType.Common.rawValue, CommonSubType.PING.rawValue, "ping")
        let data = try! JSONEncoder().encode(signal)
        return String(data: data, encoding: .utf8)!
    }
    
    init(_ type: Int, _ subType: Int, _ body: String) {
        self.type = type
        self.subType = subType
        self.body = body
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case subType = "sub_type"
        case body = "body"
    }
    
    
    
}


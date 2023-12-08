//
//  Signal.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/20.
//

import Foundation

open class Signal: Codable {
    
    var type : Int
    var body: String
    
    static var ping : String {
        let signal = Signal(SignalType.SignalHeatBeat.rawValue, "ping")
        let data = try! JSONEncoder().encode(signal)
        return String(data: data, encoding: .utf8)!
    }
    
    init(_ type: Int, _ body: String) {
        self.type = type
        self.body = body
    }
    
    enum CodingKeys: String, CodingKey {
        case type = "type"
        case body = "body"
    }
    
}

public enum SignalType: Int {
    
    case SignalNewMessage = 0,
        SignalHeatBeat = 1,
        SignalSyncTime = 2,
        SignalConnId = 3,
        SignalKickOffUser = 4
}


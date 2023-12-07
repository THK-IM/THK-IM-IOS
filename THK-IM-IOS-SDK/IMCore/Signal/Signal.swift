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
        let signal = Signal(SignalType.SignalPing.rawValue, "ping")
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

public enum SignalStatus: Int {
    case Init = 0,
         Connecting = 1,
         Connected = 2,
         DisConnected = 3
}

public enum SignalType: Int {
    
    case SignalNewMessage = 0,
        SignalPing = 1,
        SignalPong = 2,
        SignalSyncTime = 3,
        SignalConnId = 4,
        SignalKickOffUser = 5
}


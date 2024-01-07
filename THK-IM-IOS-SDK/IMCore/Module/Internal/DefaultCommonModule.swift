//
//  DefaultCommonModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/18.
//

import Foundation

open class DefaultCommonModule : CommonModule {
    
    private let client = "client"
    private let server = "server"
    private var timeMap = [String: Int64]()
    
    private var connId = ""
    private let lock = NSLock()
    
    public func getSeverTime() -> Int64 {
        lock.lock()
        defer {lock.unlock()}
        if (timeMap[client] == nil || timeMap[server] == nil) {
            return Date().timeMilliStamp
        } else {
            return timeMap[server]! + Date().timeMilliStamp - timeMap[client]!
        }
    }
    
    public func getConnId() -> String {
        return connId
    }
    
    private func setSeverTime(_ time: Int64?) {
        lock.lock()
        defer {lock.unlock()}
        if time != nil {
            timeMap[client] = Date().timeMilliStamp
            timeMap[server] = time
        }
    }
    
    public func onSignalReceived(_ type: Int, _ body: String) {
        if type == SignalType.SignalHeatBeat.rawValue {
            IMCoreManager.shared.getMessageModule().ackMessagesToServer()
        } else if type == SignalType.SignalSyncTime.rawValue {
            let time = Int64(body)
            self.setSeverTime(time)
        } else if type == SignalType.SignalConnId.rawValue {
            connId = body
        } 
    }
    
    public func beKickOff() {
        
    }
}

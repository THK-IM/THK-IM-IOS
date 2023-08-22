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
    
    func getSeverTime() -> Int64 {
        lock.lock()
        defer {lock.unlock()}
        if (timeMap[client] == nil || timeMap[server] == nil) {
            return Date().timeMilliStamp
        } else {
            return timeMap[server]! + Date().timeMilliStamp - timeMap[client]!
        }
    }
    
    func getConnId() -> String {
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
    
    
    func onSignalReceived(_ subType: Int, _ body: String) {
        if subType == CommonSubType.PONG.rawValue {
            IMCoreManager.shared.getMessageModule().ackMessagesToServer()
        } else if subType == CommonSubType.ServerTime.rawValue {
            let time = Int64(body)
            self.setSeverTime(time)
        } else if subType == CommonSubType.ConnId.rawValue {
            connId = body
        }
    }
}

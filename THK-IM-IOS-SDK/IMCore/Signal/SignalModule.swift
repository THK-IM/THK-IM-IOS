//
//  SignalModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/20.
//

import Foundation

protocol SignalModule : AnyObject {
    
    func updateToken(_ token: String)
    
    func connect()
    
    func sendMessage(_ message: String)
    
    func disconnect(_ reason: String)
    
    func getConnectStatus() -> ConnectStatus
    
    func setSignalListener(_ listener: SignalListener) 
}

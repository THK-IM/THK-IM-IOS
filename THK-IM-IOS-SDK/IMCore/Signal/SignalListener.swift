//
//  SignalListener.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/20.
//

import Foundation

protocol SignalListener {
    
    func onStatusChange(_ status: ConnectStatus)
    
    func onNewMessage(_ type: Int, _ subType: Int, _ body: String)
    
}

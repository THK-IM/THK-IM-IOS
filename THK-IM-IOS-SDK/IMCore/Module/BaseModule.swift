//
//  BaseModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation

public protocol BaseModule : AnyObject {
    
    func reset()
    
    func onSignalReceived(_ type: Int, _ body: String)
}

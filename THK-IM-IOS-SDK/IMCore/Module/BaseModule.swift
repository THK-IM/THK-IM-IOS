//
//  BaseModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/21.
//

import Foundation

protocol BaseModule : AnyObject {
    
    func onSignalReceived(_ subType: Int, _ body: String)
}

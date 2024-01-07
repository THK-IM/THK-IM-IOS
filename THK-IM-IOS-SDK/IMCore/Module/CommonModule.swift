//
//  CommonModule.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/15.
//

import Foundation

public protocol CommonModule: BaseModule {
    
    func getSeverTime() -> Int64
    
    func getConnId() -> String
    
    func beKickOff()
    
}

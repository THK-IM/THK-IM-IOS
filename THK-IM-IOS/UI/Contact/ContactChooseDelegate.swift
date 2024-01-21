//
//  ContactChooseDelegate.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/13.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

public protocol ContactChooseDelegate: AnyObject {
    
    func onContactChoose(ids: Set<Int64>)
    
}

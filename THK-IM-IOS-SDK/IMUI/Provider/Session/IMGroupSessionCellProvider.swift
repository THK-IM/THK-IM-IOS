//
//  IMGroupSessionCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/1/13.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

open class IMGroupSessionCellProvider: IMBaseSessionCellProvider {
    
    open override func sessionType() -> Int {
        return SessionType.Group.rawValue
    }
    
    open override func viewCell() -> IMBaseSessionCell {
        return GroupSessionCell(style: .default, reuseIdentifier: self.identifier())
    }
}

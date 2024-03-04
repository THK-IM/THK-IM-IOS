//
//  IMSuperGroupCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2024/2/17.
//  Copyright © 2024 THK. All rights reserved.
//

import Foundation

open class IMSuperGroupSessionCellProvider: IMBaseSessionCellProvider {
    
    open override func sessionType() -> Int {
        return SessionType.SuperGroup.rawValue
    }
    
    open override func viewCell() -> IMBaseSessionCell {
        return GroupSessionCell(style: .default, reuseIdentifier: self.identifier())
    }
}


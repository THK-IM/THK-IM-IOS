//
//  IMSingleSessionCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizss on 2023/11/4.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

open class IMSingleSessionCellProvider: IMBaseSessionCellProvider {
    
    open override func sessionType() -> Int {
        return SessionType.Single.rawValue
    }
    
    open override func viewCell() -> BaseSessionCell {
        return SingleSessionCell(style: .default, reuseIdentifier: self.identifier())
    }
}

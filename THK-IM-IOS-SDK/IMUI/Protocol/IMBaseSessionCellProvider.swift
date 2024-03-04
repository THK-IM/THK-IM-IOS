//
//  IMBaseSessionCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/7/8.
//

import Foundation
import UIKit

open class IMBaseSessionCellProvider {
    
    open func sessionType() -> Int {
        return 0
    }
    
    func identifier() -> String {
        return "session_cell_\(self.sessionType())"
    }
    
    open func viewCell() -> IMBaseSessionCell {
        return IMBaseSessionCell(style: .default, reuseIdentifier: self.identifier())
    }
}

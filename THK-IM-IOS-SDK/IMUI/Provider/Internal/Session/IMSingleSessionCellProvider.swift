//
//  IMSingleSessionCellProvider.swift
//  THK-IM-IOS
//
//  Created by vizss on 2023/11/4.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

public class IMSingleSessionCellProvider: IMBaseSessionCellProvider {
    
    public override func sessionType() -> Int {
        return SessionType.Single.rawValue
    }
    
    override public func viewCell() -> BaseSessionCell {
        return SingleSessionCell(style: .default, reuseIdentifier: self.identifier())
    }
}

//
//  IMSessionCellOperator.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/5.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

public protocol IMSessionCellOperator: AnyObject {

    func updateSession(_ session: Session)

    func deleteSession(_ session: Session)

    func openSession(_ session: Session)
}

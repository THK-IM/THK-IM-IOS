//
//  Double+DP.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/10/14.
//  Copyright © 2023 THK. All rights reserved.
//

import UIKit

extension Double {

    public func pxValue() -> Double {
        return Double(UIScreen.main.scale) * self
    }

    public func ptValue() -> Double {
        return self / Double(UIScreen.main.scale)
    }

}

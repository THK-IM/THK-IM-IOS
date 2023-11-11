//
//  Date+stamp.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/5/20.
//

import Foundation

extension Date {
    
    /// 获取当前 秒级 时间戳 - 10位
    var timeSecondStamp : Int64 {
        let timeInterval: TimeInterval = self.timeIntervalSince1970
        return Int64(timeInterval)
    }
    
    /// 获取当前 毫秒级 时间戳 - 13位
    var timeMilliStamp : Int64 {
        let timeInterval: TimeInterval = self.timeIntervalSince1970 * 1000
        return Int64(timeInterval)
    }


}

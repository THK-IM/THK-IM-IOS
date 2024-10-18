//
//  DateUtils.swift
//  THK-IM-IOS
//
//  Created by vizoss on 2023/11/11.
//  Copyright © 2023 THK. All rights reserved.
//

import Foundation

public class DateUtils {

    public static func secondToDuration(seconds: Int) -> String {
        let h = seconds / 3600
        let m = seconds / 60
        let s = seconds % 60
        return h == .zero
            ? String(format: "%02ld:%02ld", m, s) : String(format: "%02ld:%02ld:%02ld", h, m, s)
    }

    public static func timeToMsgTime(ms: Int64, now: Int64) -> String {
        let nowDate = Date(timeIntervalSince1970: TimeInterval(now / 1000))
        let showDate = Date(timeIntervalSince1970: TimeInterval(ms / 1000))

        // 使用系统日历对象
        var calendar = Calendar.current
        calendar.firstWeekday = 2  // 设置周一为周第一天，符合CN周显示
        let set =
            NSSet.init(array: [
                Calendar.Component.year,
                Calendar.Component.month,
                Calendar.Component.weekOfMonth,
                Calendar.Component.weekOfYear,  // 一年中的第几个周
                Calendar.Component.weekday,
                Calendar.Component.day,
                Calendar.Component.hour,
                Calendar.Component.minute,
                Calendar.Component.second,
            ]
            ) as! Set<Calendar.Component>
        let nowDateComp = calendar.dateComponents(set, from: nowDate)
        let showDateComp = calendar.dateComponents(set, from: showDate)

        if showDateComp.year == nowDateComp.year
            && showDateComp.month == nowDateComp.month
            && showDateComp.day == nowDateComp.day
        {
            let formatter = DateFormatter()
            formatter.dateFormat = "HH:mm"
            return formatter.string(from: showDate)
        }

        // 不是同一年返回 "yyyy年MM月dd日 HH:mm"
        if showDateComp.year != nowDateComp.year {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd"
            return formatter.string(from: showDate)
        }

        let formatter = DateFormatter()
        formatter.dateFormat = "MM-dd"
        return formatter.string(from: showDate)
    }
}

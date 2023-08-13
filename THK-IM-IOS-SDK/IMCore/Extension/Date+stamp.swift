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
    
    private func plus(_ number: Int) -> String {
        if number < 10 {
            return "0\(number)"
        }
        return "\(number)"
    }
    
    func secondToTime(_ seconds: Int) -> String {
        let hours = seconds / 3600
        let minutes = seconds / 60
        let seconds = seconds % 60
        return hours == .zero ? String(format: "%02ld:%02ld", minutes, seconds) : String(format: "%02ld:%02ld:%02ld", hours, minutes, seconds)
    }
    
    // 时间戳转具体时间  time 是时间戳，毫秒
    func timeToDateString(showTime: Int64, currentTime: Int64) -> String {
        let nowDate = Date(timeIntervalSince1970: TimeInterval(currentTime/1000))
        let showDate = Date(timeIntervalSince1970: TimeInterval(showTime/1000))
        
        // 使用系统日历对象
        var calendar = Calendar.current
        calendar.firstWeekday = 2 // 设置周一为周第一天，符合CN周显示
        let set = NSSet.init(array: [Calendar.Component.year,
                                     Calendar.Component.month,
                                     Calendar.Component.weekOfMonth,
                                     Calendar.Component.weekOfYear,// 一年中的第几个周
                                     Calendar.Component.weekday,
                                     Calendar.Component.day,
                                     Calendar.Component.hour,
                                     Calendar.Component.minute,
                                     Calendar.Component.second]
        ) as! Set<Calendar.Component>
        let nowDateComp = calendar.dateComponents(set, from: nowDate)
        let showDateComp = calendar.dateComponents(set, from: showDate)
        
        // 不是同一年返回 "yyyy年MM月dd日 HH:mm"
        if showDateComp.year != nowDateComp.year {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy年MM月dd日 HH:mm"
            return formatter.string(from: showDate)
        }
        
        // 不是同一个月返回 "MM月dd日 HH:mm"
        if showDateComp.month != nowDateComp.month {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM月dd日 HH:mm"
            return formatter.string(from: showDate)
        }
        
        guard let nowDay = nowDateComp.day else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM月dd日 HH:mm"
            return formatter.string(from: showDate)
        }
        
        guard let showDay = showDateComp.day else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM月dd日 HH:mm"
            return formatter.string(from: showDate)
        }
        
        // 相差超过1周 "MM月dd日 HH:mm"
        if abs(nowDay - showDay) > 6 {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM月dd日 HH:mm"
            return formatter.string(from: showDate)
        }
        
        
        guard let showWeekDay = showDateComp.weekday else {
            let formatter = DateFormatter()
            formatter.dateFormat = "MM月dd日 HH:mm"
            return formatter.string(from: showDate)
        }
        
        var dateString = ""
        // 天差。与当前天比较，正为昨天、前天，负数为明、后天
        let diffDay = twoTimeDiffDay(fromTime: showDate, endTime: nowDate)
        if isSameDay(beginDate: showDateComp, endDate: nowDateComp) {
            dateString = ""
        } else if diffDay == 1 {
            dateString = "昨天"
        } else if diffDay == 2 {
            dateString = "前天"
        } else {
            dateString = "星期\(weekToDateString(weekDay: showWeekDay))"
        }
        let formatter = DateFormatter()
        formatter.dateFormat = " HH:mm"
        let time = formatter.string(from: showDate)
        dateString += time
        return dateString
    }
    
    // 是否是同一天 要加上年、月、日一起判断
    private func isSameDay(beginDate: DateComponents, endDate: DateComponents) -> Bool {
        return beginDate.year == endDate.year
        && beginDate.month == endDate.month
        && beginDate.day == endDate.day
    }
    
    
    // 两个时间的差
    private func twoTimeDiffDay(fromTime: Date, endTime: Date, calendar: Calendar = .current) -> Int {
        let formerTime = calendar.startOfDay(for: fromTime)
        let endTime = calendar.startOfDay(for: endTime)
        // 默认一个比较大的值，就显示具体时间了
        return calendar.dateComponents([.day], from: formerTime, to: endTime).day ?? 1000
    }

    
    private func weekToDateString(weekDay: Int) -> String {
        var dayString = ""
        switch weekDay {
        case 1:
            dayString = "日"
        case 2:
            dayString = "一"
        case 3:
            dayString = "二"
        case 4:
            dayString = "三"
        case 5:
            dayString = "四"
        case 6:
            dayString = "五"
        case 7:
            dayString = "六"
        default:
            dayString = "NA"
        }
        return dayString
    }


}

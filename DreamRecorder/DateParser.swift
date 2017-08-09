//
//  DateParser.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 8..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import Foundation

struct DateParser {
    
    private let calendar = Calendar(identifier: .gregorian)
    
    func time(from date : Date) -> String? {
        let component = calendar.dateComponents([.hour, .minute], from: date)
        guard let hour = component.hour,
            let minute = component.minute else {
                return nil
        }
        if hour > 12 {
            return "\(hour - 12):" + String(format: "%02d", minute) + " PM"
        }
        return "\(hour):\(minute) AM"
    }
    
    func day(from date: Date) -> String? {
        let day = calendar.component(.day, from: date)
        return String(day)
    }
    
    func month(from date: Date) -> String? {
        guard let monthSymbols = DateFormatter().shortMonthSymbols else {
            return nil
        }
        let month = calendar.component(.month, from: date)
        return monthSymbols[month - 1]
    }
    
    func dayOfWeek(from date: Date) -> String? {
        let component = calendar.dateComponents([.weekday], from: date)
        guard let weekdaySymbols = DateFormatter().weekdaySymbols,
            let weekday = component.weekday else {
                return nil
        }
        return weekdaySymbols[weekday - 1]
    }
    
    func detail(from date: Date) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.dateStyle = .medium
        return dateFormatter.string(from: date)
    }
}

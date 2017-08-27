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
    
    static private(set) var dateFormatter : DateFormatter = {
        
        var dateFormatter = DateFormatter()
        dateFormatter.locale = Locale.current
        dateFormatter.dateStyle = .medium
        return dateFormatter
        
    }()
    
    func firstDayOfMonth(date: Date) -> Date? {
        
        let month = calendar.dateComponents([.month], from: date).month
        
        let component : DateComponents = {
            var component = DateComponents()
            (component.month, component.day) = (month, 1)
            return component
        }()
        
        return component.date
    }
    
    func time(from date : Date) -> String? {
        
        let component = calendar.dateComponents([.hour, .minute], from: date)
        
        guard let hour = component.hour,
            let minute = component.minute else {
                return nil
        }
        
        if hour > 12 {
            return "\(String(format: "%02d", hour - 12)):\(String(format: "%02d", minute)) PM"
        } else if hour == 12 {
            return "\(String(format: "%02d", hour)):\(String(format: "%02d", minute)) PM"
        }
        return "\(String(format: "%02d", hour)):\(String(format: "%02d", minute)) AM"
        
    }
    
    func year(from date: Date) -> Int? {
        
        let component = calendar.dateComponents([.year], from: date)
        
        guard let year = component.year else {
            return nil
        }
        
        return year

    }
    
    func day(from date: Date) -> String? {
        
        let day = calendar.component(.day, from: date)
        return String(day)
        
    }
    
    func month(from date: Date) -> String? {
        
        guard let monthSymbols = DateParser.dateFormatter.shortMonthSymbols else {
            return nil
        }
        
        let month = calendar.component(.month, from: date)
        
        return monthSymbols[month - 1]
        
    }
    
    func month(from date: Date) -> Int {
        
        let month = calendar.component(.month, from: date)
        
        return month
        
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
        return DateParser.dateFormatter.string(from: date)
    }
}

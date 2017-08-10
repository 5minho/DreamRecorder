//
//  Alarm.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 7..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import Foundation

struct WeekdayOptions: OptionSet {
    let rawValue: Int
    
    static let sun = WeekdayOptions(rawValue: 1 << 0)
    static let mon = WeekdayOptions(rawValue: 1 << 1)
    static let tue = WeekdayOptions(rawValue: 1 << 2)
    static let wed = WeekdayOptions(rawValue: 1 << 3)
    static let thu = WeekdayOptions(rawValue: 1 << 4)
    static let fri = WeekdayOptions(rawValue: 1 << 5)
    static let sat = WeekdayOptions(rawValue: 1 << 6)
    
    static let none: WeekdayOptions = []
    static let weekdays: WeekdayOptions = [.mon, .tue, .wed, .thu, .fri]
    static let weekend: WeekdayOptions = [.sat, .sun]
    static let all: WeekdayOptions = [.mon, .tue, .wed, .thu, .fri, .sat, .sun]
}

class Alarm {
    var id : String
    var name: String
    var date: Date
    var weekday: WeekdayOptions
    var isActive: Bool
    var isSnooze: Bool
    
    init(id : String, name: String, date: Date, weekday: WeekdayOptions, isActive: Bool, isSnooze: Bool) {
        self.id = id
        self.name = name
        self.date = date
        self.weekday = weekday
        self.isActive = isActive
        self.isSnooze = isSnooze
    }
    
    init?() {
        var dateComponents = DateComponents()
        dateComponents.hour = 8
        dateComponents.minute = 0
        guard let date = Calendar.current.date(from: dateComponents) else { return nil }
        
        self.id = UUID().uuidString
        self.name = "Alarm"
        self.date = date
        self.weekday = .none
        self.isActive = true
        self.isSnooze = true
    }
}

//
//  Alarm.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 7..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import Foundation

/// 일요일(1 << 0)부터 토요일(1 << 6)까지 포함할 수 OptionSet.
///
/// Alarm 클래스의 프로퍼티로 weeday를 지님.
/// Calendar에서 기본적으로 제공하는 Weekday를 통해서 접근이 가능하다.
///
/// 주의: Calendar.current.weekdaySymbols는 0 ~ 6 인덱스를 가지는데
/// Calendar.Component.weekday는 1부터 7의 값을 가진다.
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

class Alarm: NSObject, NSCopying {
    var id : String
    var name: String
    var date: Date
    var weekday: WeekdayOptions
    var sound: String
    var isActive: Bool
    var isSnooze: Bool
    
    init(id : String = UUID().uuidString,
         name: String = "Alarm",
         date: Date = Date(),
         weekday: WeekdayOptions = .none,
         sound: String = "Default.wav",
         isActive: Bool = true,
         isSnooze: Bool = true) {
        
        self.id = id
        self.name = name
        self.date = date
        self.weekday = weekday
        self.sound = sound
        self.isActive = isActive
        self.isSnooze = isSnooze
    }
    
    public static func ==(lhs: Alarm, rhs: Alarm) -> Bool {
        return (lhs.id == rhs.id)
    }
    
    func copy(with zone: NSZone? = nil) -> Any {
        let copiedAlarm = Alarm(id: id, name: name, date: date, weekday: weekday, sound: sound, isActive: isActive, isSnooze: isSnooze)
        return copiedAlarm
    }
}

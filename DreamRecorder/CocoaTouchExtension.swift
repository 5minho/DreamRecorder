//
//  CocoaTouchExtension.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 9..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//
import Foundation
import SQLite

// MARK: Foundation
// extension dataType to read and write at sqlite database for type suppport
// TRICK: reading WeekdayOptions as Int invoke error, so use Int64 as Int Wrapper.

extension WeekdayOptions: Value {
    static var declaredDatatype: String {
        return Int64.declaredDatatype
    }
    static func fromDatatypeValue(_ datatypeValue: Int64) -> WeekdayOptions {
        return WeekdayOptions(rawValue: Int(datatypeValue))
    }
    var datatypeValue: Int64 {
        return Int64(rawValue)
    }
}

extension Bool {
    static var declaredDatatype: String {
        return Int.declaredDatatype
    }
    static func fromDatatypeValue(intValue: Int) -> Bool {
        return intValue == 1 ? true : false
    }
    var datatypeValue: Int {
        return self ? 1 : 0
    }
}

extension Date {
    static var declaredDatatype: String {
        return Int.declaredDatatype
    }
    static func fromDatatypeValue(intValue: Int) -> Date {
        return self.init(timeIntervalSince1970: TimeInterval(intValue))
    }
    var datatypeValue: Int {
        return Int(timeIntervalSince1970)
    }
}


extension Date {
    func compareByMinuteUnit(other date: Date) -> Bool {
        return (Calendar.current.compare(self, to: date, toGranularity: .minute) == .orderedSame)
    }
}

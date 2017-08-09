//
//  AlarmDataStore.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 7..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import Foundation
import SQLite

// MARK: Extension DataType
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

class AlarmDataStore: NSObject {
    
    // this structure configure alarm table at sqlite db
    private struct AlarmTable {
        static let table = Table("alarms")
        
        struct Column {
            static let id = Expression<String>("id")
            static let name = Expression<String>("name")
            static let date = Expression<Date>("date")
            static let weekday = Expression<WeekdayOptions>("weekday")
            static let isActive = Expression<Bool>("isActive")
            static let isSnooze = Expression<Bool>("isSnooze")
        }
    }
    
    private let manager: DBManagerable = DBManager.shared
    
    // this alarms array is varaible that is loaded from database to memory and application will access this array for data
    var alarms: [Alarm] = []
    
    func createTable(){
        let tableResult = self.manager.createTable(statement: AlarmTable.table.create { (t) in
            t.column(AlarmTable.Column.id, primaryKey: true)
            t.column(AlarmTable.Column.name)
            t.column(AlarmTable.Column.date)
            t.column(AlarmTable.Column.weekday)
            t.column(AlarmTable.Column.isActive)
            t.column(AlarmTable.Column.isSnooze)
        })
        
        switch tableResult {
        case .success:
            print("Success: create table")
        case let .failure(error):
            print("error: \(error)")
        }
    }
    
    func reloadAlarms(){
        self.alarms = self.selectAll()
    }
    
    private func selectAll() -> [Alarm] {
        let rowsResult = manager.selectAll(query: AlarmTable.table)
        switch rowsResult {
        case let .success(rows):
            var newAlarms: [Alarm] = []
            for alarm in rows {
                let alarmLoaded = Alarm(id: alarm[AlarmTable.Column.id],
                                        name: alarm[AlarmTable.Column.name],
                                        date: alarm[AlarmTable.Column.date],
                                        weekday: alarm.get(AlarmTable.Column.weekday),
                                        isActive: alarm.get(AlarmTable.Column.isActive),
                                        isSnooze: alarm.get(AlarmTable.Column.isSnooze))
                newAlarms.append(alarmLoaded)
            }
            print("Success: select all \(rows.underestimatedCount))")
            return newAlarms
        case let .failure(error):
            print(error)
            return []
        }
        
    }
    
    func insertAlarm(alarm: Alarm) {
        let insert = AlarmTable.table.insert(AlarmTable.Column.id <- alarm.id,
                                             AlarmTable.Column.name <- alarm.name,
                                             AlarmTable.Column.date <- alarm.date,
                                             AlarmTable.Column.weekday <- alarm.weekday,
                                             AlarmTable.Column.isActive <- alarm.isActive,
                                             AlarmTable.Column.isSnooze <- alarm.isSnooze)
        
        let result = manager.insertRow(insert: insert)
        
        switch result {
        case let .success(rowID):
            print("Success: insert row \(rowID)")
        case let .failure(error):
            print(error)
        }
    }
    
    func updateAlarm(alarm: Alarm) {
        let updateRow = AlarmTable.table.filter(AlarmTable.Column.id == alarm.id)
        let result = self.manager.updateRow(update: updateRow.update(AlarmTable.Column.id <- alarm.id,
                                                                     AlarmTable.Column.name <- alarm.name,
                                                                     AlarmTable.Column.date <- alarm.date,
                                                                     AlarmTable.Column.weekday <- alarm.weekday,
                                                                     AlarmTable.Column.isActive <- alarm.isActive,
                                                                     AlarmTable.Column.isSnooze <- alarm.isSnooze))
        switch result {
        case .success:
            print("Success: update row \(alarm.id)")
        case let .failure(error):
            print("error: \(error)")
        }
    }
    
    func deleteAlarm(alarm: Alarm) {
        let deletingRow = AlarmTable.table.filter(AlarmTable.Column.id == alarm.id)
        let result = self.manager.deleteRow(delete: deletingRow.delete())
        switch result {
        case .success:
            print("Success: delete row \(alarm.id)")
        case let .failure(error):
            print("error: \(error)")
        }
    }
}

//
//  AlarmDataStore.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 7..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import Foundation
import SQLite

extension Notification.Name {
    static let AlarmDateStoreDidSyncAlarmAndNotification = Notification.Name("AlarmDateStoreDidSyncAlarmAndNotification")
}

class AlarmDataStore: NSObject {

    static let shared: AlarmDataStore = AlarmDataStore()
    
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
    lazy var scheduler: AlarmScheduler = AlarmScheduler()
    
    func createTable(){
        let tableResult = self.manager.createTable(statement: AlarmTable.table.create(ifNotExists: true) { (t) in
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
    
    func alarm(withNotificationIdentifier identifier: String) -> Alarm? {
        let alarm = self.alarms.filter { identifier.contains($0.id) }
        return alarm.first
    }
    
    func reloadAlarms(){
        self.alarms = self.selectAll()
        self.syncAlarmAndNotification()
    }
    
    func syncAlarmAndNotification() {
        if #available(iOS 10.0, *) {
//            self.scheduler.getDeliveredNotifications(completionHandler: { (notifications) in
//                var inActiveAlarms: [Alarm] = []
//                for notification in notifications {
//                    print(notification.request.identifier)
//                    let inActiveAlarm = self.alarms.filter { $0.id == notification.request.identifier }
//                    inActiveAlarms += inActiveAlarm
//                    print(inActiveAlarm)
//                }
//                
//                for alarm in inActiveAlarms {
//                    alarm.isActive = false
//                    self.updateAlarm(alarm: alarm)
//                    self.reloadAlarms()
//                    print(alarm)
//                    NotificationCenter.default.post(name: didSyncAlarmAndNotification, object: nil)
//                }
//            })
            self.scheduler.getPendingNotificationRequests(completion: { (requests) in
                let inActiveAlarms = self.alarms.filter({ (alarm) -> Bool in
                    var isDelivered = true
                    for request in requests {
                        let identifier = request.identifier
                        if (identifier == alarm.id) {
                            isDelivered = false
                            break
                        }
                    }
                    return isDelivered
            })
                
            for alarm in inActiveAlarms {
                alarm.isActive = false
                self.updateAlarm(alarm: alarm)
                self.reloadAlarms()
                NotificationCenter.default.post(name: Notification.Name.AlarmDateStoreDidSyncAlarmAndNotification, object: nil)
                }})
        } else {
            guard let notifications = self.scheduler.getScheduledLocalNotifications() else { return }
            let inActiveAlarms = self.alarms.filter({ (alarm) -> Bool in
                var isDelivered = true
                for notification in notifications {
                    guard let identifier = notification.userInfo?["identifier"] as? String else { continue }
                    if (identifier == alarm.id) {
                        isDelivered = false
                        break
                    }
                }
                return isDelivered
            })
            
            for alarm in inActiveAlarms {
                alarm.isActive = false
                self.updateAlarm(alarm: alarm)
                self.reloadAlarms()
                NotificationCenter.default.post(name: Notification.Name.AlarmDateStoreDidSyncAlarmAndNotification, object: nil)
            }
        }
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
            self.scheduler.addNotification(with: alarm)
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
            self.scheduler.updateNotification(with: alarm)
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
            self.scheduler.deleteNotification(with: alarm)
            print("Success: delete row \(alarm.id)")
        case let .failure(error):
            print("error: \(error)")
        }
    }
}

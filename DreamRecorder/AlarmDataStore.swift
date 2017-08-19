//
//  AlarmDataStore.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 7..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import Foundation
import SQLite

extension Connection {
    public var user_version: Int32 {
        get { return Int32(try! scalar("PRAGMA user_version") as? Int64 ?? 0) }
        set { try! run("PRAGMA user_version = \(newValue)") }
    }
}

extension Notification.Name {
    // for AlarmScheduler.
    static let AlarmDataStoreDidAddAlarm = Notification.Name("AlarmDataStoreDidAddAlarm")
    static let AlarmDataStoreDidUpdateAlarm = Notification.Name("AlarmDataStoreDidUpdateAlarm")
    static let AlarmDataStoreDidDeleteAlarm = Notification.Name("AlarmDataStoreDidDeleteAlarm")
    
    // for AlarmListViewController.
    static let AlarmDataStoreDidChange = Notification.Name("AlarmDataStoreDidChange")
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
            static let sound = Expression<String>("sound")
            static let isActive = Expression<Bool>("isActive")
            static let isSnooze = Expression<Bool>("isSnooze")
        }
    }
    
    private let manager: DBManagerable = DBManager.shared
    
    // this alarms array is varaible that is loaded from database to memory and application will access this array for data
    var alarms: [Alarm] = []
    
    override init() {
        super.init()
        AlarmDataStore.migarationIfNeeded()
        
        // add observer scheduler notification.
        NotificationCenter.default.addObserver(self, selector: #selector(self.self.updateOnceNotificationActive(sender:)), name: Notification.Name.AlarmSchedulerNotificationDidDelivered, object: nil)
        // From resent or recevive notification.
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleApplicationWillPresentNotification(sender:)), name: Notification.Name.ApplicationWillPresentNotification, object: nil)
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleApplicationDidReceiveResponse(sender:)), name: Notification.Name.ApplicationDidReceiveResponse, object: nil)
    }
    
    func handleApplicationWillPresentNotification(sender: Notification) {
        guard let identifier = sender.userInfo?["identifier"] as? String else { return }
        guard let responsedAlarm = self.alarm(withNotificationIdentifier: identifier) else { return }
        if responsedAlarm.weekday == .none {
            responsedAlarm.isActive = false
            self.updateAlarm(alarm: responsedAlarm)
        }
    }
    
    func handleApplicationDidReceiveResponse(sender: Notification) {
        guard let identifier = sender.userInfo?["identifier"] as? String else { return }
        guard let actionIdentifier = sender.userInfo?["actionIdentifier"] as? String else { return }
        guard let responsedAlarm = self.alarm(withNotificationIdentifier: identifier) else { return }
        
        if actionIdentifier == "StopAction" {
            if responsedAlarm.weekday == .none {
                responsedAlarm.isActive = false
                self.updateAlarm(alarm: responsedAlarm)
            }
        } else {
            // TODO: CONTROL SNOOZE.
        }
    }
    
    @objc private func updateOnceNotificationActive(sender: Notification) {
        guard let inActiveAlarms = sender.userInfo?["alarms"] as? [Alarm] else { return }
        
        for inActiveAlarm in inActiveAlarms {
            inActiveAlarm.isActive = false
            self.updateAlarm(alarm: inActiveAlarm)
        }
        NotificationCenter.default.post(name: Notification.Name.AlarmDataStoreDidUpdateAlarm, object: nil)
    }
    
    static func migarationIfNeeded(){
        if DBManager.shared.db.user_version == 0 {
            AlarmDataStore.createTable()
            DBManager.shared.db.user_version = 1
        }
        if DBManager.shared.db.user_version == 1 {
            do {
                try DBManager.shared.db.run(AlarmTable.table.addColumn(AlarmTable.Column.sound, defaultValue: "Default"))
                print("Alarm Table is Updated")
                DBManager.shared.db.user_version = 2
            } catch {
                print(error)
            }
        }
    }
    
    static func createTable(){
        let tableResult = DBManager.shared.createTable(statement: AlarmTable.table.create(ifNotExists: true) { (t) in
            t.column(AlarmTable.Column.id, primaryKey: true)
            t.column(AlarmTable.Column.name)
            t.column(AlarmTable.Column.date)
            t.column(AlarmTable.Column.weekday)
            t.column(AlarmTable.Column.sound)
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
                                        sound: alarm.get(AlarmTable.Column.sound),
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
        self.alarms.append(alarm)
        let insert = AlarmTable.table.insert(AlarmTable.Column.id <- alarm.id,
                                             AlarmTable.Column.name <- alarm.name,
                                             AlarmTable.Column.date <- alarm.date,
                                             AlarmTable.Column.weekday <- alarm.weekday,
                                             AlarmTable.Column.sound <- alarm.sound,
                                             AlarmTable.Column.isActive <- alarm.isActive,
                                             AlarmTable.Column.isSnooze <- alarm.isSnooze)
        
        let result = manager.insertRow(insert: insert)
        
        switch result {
        case let .success(rowID):
            NotificationCenter.default.post(name: Notification.Name.AlarmDataStoreDidAddAlarm,
                                            object: nil,
                                            userInfo: ["alarm": alarm])
            NotificationCenter.default.post(name: Notification.Name.AlarmDataStoreDidChange,
                                            object: nil,
                                            userInfo: ["alarm": alarm])
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
                                                                     AlarmTable.Column.sound <- alarm.sound,
                                                                     AlarmTable.Column.isActive <- alarm.isActive,
                                                                     AlarmTable.Column.isSnooze <- alarm.isSnooze))
        switch result {
        case .success:
            NotificationCenter.default.post(name: Notification.Name.AlarmDataStoreDidUpdateAlarm,
                                            object: nil,
                                            userInfo: ["alarm" : alarm])
            NotificationCenter.default.post(name: Notification.Name.AlarmDataStoreDidChange,
                                            object: nil,
                                            userInfo: ["alarm": alarm])
            print("Success: update row \(alarm.id)")
        case let .failure(error):
            print("error: \(error)")
        }
    }
    
    func deleteAlarm(alarm: Alarm) {
        guard let row = self.alarms.index(of: alarm) else { return }
        self.alarms.remove(at: row)
        
        let deletingRow = AlarmTable.table.filter(AlarmTable.Column.id == alarm.id)
        let result = self.manager.deleteRow(delete: deletingRow.delete())
        switch result {
        case .success:
            NotificationCenter.default.post(name: Notification.Name.AlarmDataStoreDidDeleteAlarm,
                                            object: nil,
                                            userInfo: ["alarm" : alarm])
            NotificationCenter.default.post(name: Notification.Name.AlarmDataStoreDidChange,
                                            object: nil,
                                            userInfo: ["alarm": alarm])
            print("Success: delete row \(alarm.id)")
        case let .failure(error):
            print("error: \(error)")
        }
    }
}

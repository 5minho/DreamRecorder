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

struct AlarmNotificationUserInfoKey {
    static let alarm = "alarm"
    static let alarms = "alarms"
    static let nextTriggerDate = "nextTriggerDate"
}

extension Notification.Name {
    // AlarmDataStore -> AlarmScheduler.
    // @discussion      The userInfo dictionary contains an alarm object that is changed.
    //                  Use AlarmNotificationUserInfoKey to access this value.
    static let AlarmDataStoreDidAddAlarm = Notification.Name("AlarmDataStoreDidAddAlarm")
    static let AlarmDataStoreDidUpdateAlarm = Notification.Name("AlarmDataStoreDidUpdateAlarm")
    static let AlarmDataStoreDidDeleteAlarm = Notification.Name("AlarmDataStoreDidDeleteAlarm")
    
    // AlarmDataStore -> AlarmListViewController(UI).
    static let AlarmDataStoreDidChange = Notification.Name("AlarmDataStoreDidChange")
}

class AlarmDataStore: NSObject {
    
    // MARK: Properties.
    // Singleton.
    static let shared: AlarmDataStore = AlarmDataStore()
    
    // @abstract        This structure configure alarm table(table name and columns at sqlite db.
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
    
    // Internal.
    var alarms: [Alarm] // Array that is loaded from database to memory and controller will access this array for view.
    
    // Private.
    private let manager: DBManagerable = DBManager.shared
    
    // MARK: Initializer.
    override init() {
        self.alarms = []
        
        super.init()
        
        AlarmDataStore.migarationIfNeeded()
        self.alarms = self.selectAll()
        
        // AlarmScheduler -> AlarmDataStore.
        NotificationCenter.default.addObserver(self, selector: #selector(self.updateOnceNotificationActive(sender:)), name: Notification.Name.AlarmSchedulerNotificationDidDelivered, object: nil)
        
        // Application -> AlarmDataStore.
//        NotificationCenter.default.addObserver(self, selector: #selector(self.handleApplicationWillPresentNotification(sender:)), name: Notification.Name.ApplicationWillPresentNotification, object: nil)
//        NotificationCenter.default.addObserver(self, selector: #selector(self.handleApplicationDidReceiveResponse(sender:)), name: Notification.Name.ApplicationDidReceiveResponse, object: nil)
    }
    
    func awake() {}
    
    // MARK: Handler.
    // 
//    func handleApplicationWillPresentNotification(sender: Notification) {
//        guard let identifier = sender.userInfo?["identifier"] as? String else { return }
//        guard let responsedAlarm = self.alarm(withNotificationIdentifier: identifier) else { return }
//        if responsedAlarm.weekday == .none {
//            responsedAlarm.isActive = false
//            self.updateAlarm(alarm: responsedAlarm)
//        }
//    }
    
//    func handleApplicationDidReceiveResponse(sender: Notification) {
//        guard let identifier = sender.userInfo?["identifier"] as? String else { return }
//        guard let actionIdentifier = sender.userInfo?["actionIdentifier"] as? String else { return }
//        guard let responsedAlarm = self.alarm(withNotificationIdentifier: identifier) else { return }
//        
//        if actionIdentifier == "StopAction" {
//            if responsedAlarm.weekday == .none {
//                responsedAlarm.isActive = false
//                self.updateAlarm(alarm: responsedAlarm)
//            }
//        } else {
//            // TODO: CONTROL SNOOZE.
//        }
//    }
    
    // @abstract        Update alarm`s inActive to false if alarm has no repeat day.
    // @discussion      This method should be called if once notification did change.
    //                  AlarmScheduler will trigger this handler (by posting AlarmSchedulerNotificationDidDelivered)
    //                  When WillPresentNotification(for foreground) and didEndForeground(for background & suspended)
    @objc private func updateOnceNotificationActive(sender: Notification) {
        guard let inActiveAlarms = sender.userInfo?[AlarmNotificationUserInfoKey.alarms] as? [Alarm] else { return }
        
        for inActiveAlarm in inActiveAlarms {
            var shouldNotificationUpdate = false
            if inActiveAlarm.isActive {
                inActiveAlarm.isActive = false
                self.updateAlarm(alarm: inActiveAlarm)
                shouldNotificationUpdate = true
            }
            if shouldNotificationUpdate {
                NotificationCenter.default.post(name: Notification.Name.AlarmDataStoreDidUpdateAlarm, object: nil)
            }
        }
    }
    
    
    // @abstract        Migrate alarm table if needed.
    static func migarationIfNeeded(){
        if DBManager.shared.db.user_version == 0 {
            AlarmDataStore.createTable()
            DBManager.shared.db.user_version = 1
        }
        if DBManager.shared.db.user_version == 1 {
            do {
                try DBManager.shared.db.run(AlarmTable.table.addColumn(AlarmTable.Column.sound, defaultValue: "Default.wav"))
                DBManager.shared.db.user_version = 2
            } catch {
                print(error)
            }
        }
    }
    
    // @abstract        Create alarm table if needed.
    // @discussion      It`s up to SQLite Library to decide whether table should be created or not.
    static func createTable(){
        let tableResult = DBManager.shared.createTable(statement: AlarmTable.table.create(ifNotExists: true) { (table) in
            table.column(AlarmTable.Column.id, primaryKey: true)
            table.column(AlarmTable.Column.name)
            table.column(AlarmTable.Column.date)
            table.column(AlarmTable.Column.weekday)
            table.column(AlarmTable.Column.sound)
            table.column(AlarmTable.Column.isActive)
            table.column(AlarmTable.Column.isSnooze)
        })
        
        switch tableResult {
        case .success:
            print("Success: create table if not exists.")
        case let .failure(error):
            print("error: \(error)")
        }
    }
    
    // @abstract        The alarm corresponding to identifier, or nil if no alarm is found.
    // @param           identifier: the identifier of the notification.
    // @return          `Alarm` of which notification identifier has prefix.
    func alarm(withNotificationIdentifier identifier: String) -> Alarm? {
        let alarm = self.alarms.filter { identifier.hasPrefix($0.id) }
        return alarm.first
    }
    
    // @abstract        Select all alarms from alarm table at db.
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
            print("Success: select all \(rows.underestimatedCount)")
            return newAlarms
        case let .failure(error):
            print(error)
            return []
        }
    }
    
    // @abstract        Insert Alarm at alarm table.
    // @param           alarm: The alarm element to insert.
    // @discussion      Alarm is inserted at both array(memory) and table(DB).
    //                  This method post AlarmDataStoreDidAddAlarm(for AlarmScheduler) and AlarmDataStoreDidChange(for UI)
    
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
                                            userInfo: [AlarmNotificationUserInfoKey.alarm: alarm])
            NotificationCenter.default.post(name: Notification.Name.AlarmDataStoreDidChange,
                                            object: nil,
                                            userInfo: [AlarmNotificationUserInfoKey.alarm: alarm])
            print("Success: insert row \(rowID)")
        case let .failure(error):
            print(error)
        }
    }
    
    // @abstract        Update Alarm at alarm table.
    // @param           alarm: The alarm element to update.
    // @discussion      Alarm is updated at both array(memory) and table(DB).
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
                                            userInfo: [AlarmNotificationUserInfoKey.alarm : alarm])
            NotificationCenter.default.post(name: Notification.Name.AlarmDataStoreDidChange,
                                            object: nil,
                                            userInfo: [AlarmNotificationUserInfoKey.alarm: alarm])
            print("Success: update row \(alarm.id)")
        case let .failure(error):
            print("error: \(error)")
        }
    }
    
    // @abstract        Delete Alarm at alarm table.
    // @param           alarm: The alarm element to delete.
    // @discussion      Alarm is deleted at both array(memory) and table(DB).
    func deleteAlarm(alarm: Alarm) {
        guard let row = self.alarms.index(of: alarm) else { return }
        self.alarms.remove(at: row)
        
        let deletingRow = AlarmTable.table.filter(AlarmTable.Column.id == alarm.id)
        let result = self.manager.deleteRow(delete: deletingRow.delete())
        switch result {
        case .success:
            NotificationCenter.default.post(name: Notification.Name.AlarmDataStoreDidDeleteAlarm,
                                            object: nil,
                                            userInfo: [AlarmNotificationUserInfoKey.alarm : alarm])
            NotificationCenter.default.post(name: Notification.Name.AlarmDataStoreDidChange,
                                            object: nil,
                                            userInfo: [AlarmNotificationUserInfoKey.alarm: alarm])
            print("Success: delete row \(alarm.id)")
        case let .failure(error):
            print("error: \(error)")
        }
    }
}

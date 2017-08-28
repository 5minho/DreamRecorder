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
    // MARK: - AlarmDataStore -> AlarmScheduler.
    /// AlarmDataStore에서 DB에 alarm객체를 추가/수정/삭제할 때 Notification을 Post한다.
    /// 해당 Notification의 userInfo는 추가/수정/삭제된 알람 인스턴스를 가지고 있다.
    /// userInfo에 포함된 알람 인스턴스는 AlarmNotificationUserInfoKey를 통해 접근이 가능하다.
    static let AlarmDataStoreDidAddAlarm = Notification.Name("AlarmDataStoreDidAddAlarm")
    static let AlarmDataStoreDidUpdateAlarm = Notification.Name("AlarmDataStoreDidUpdateAlarm")
    static let AlarmDataStoreDidDeleteAlarm = Notification.Name("AlarmDataStoreDidDeleteAlarm")
    
    // AlarmDataStore -> AlarmListViewController(UI).
    /// AlarmDataStore에서 DB에 alarm객체를 추가/수정/삭제할 때 Notification을 Post한다.
    /// 해당 Notification의 userInfo는 추가/수정/삭제된 알람 인스턴스를 가지고 있다.
    /// userInfo에 포함된 알람 인스턴스는 AlarmNotificationUserInfoKey를 통해 접근이 가능하다.
    static let AlarmDataStoreDidChange = Notification.Name("AlarmDataStoreDidChange")
}

class AlarmDataStore: NSObject {
    
    /// SQLite DB에 접근할 때 활용되는 알람 테이블의 테이블명과 Colume의 대한 정보를 가지고 있다.
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
    
    // MARK: - Properties.
    // Singleton.
    static let shared: AlarmDataStore = AlarmDataStore()
    
    // - Internal.
    var alarms: [Alarm] // Array that is loaded from database to memory and controller will access this array for view.
    
    // - Private.
    private let manager: DBManagerable = DBManager.shared
    
    // MARK: - Initializer.
    override init() {
        self.alarms = []
        
        super.init()
        
        AlarmDataStore.migarationIfNeeded()
        self.alarms = self.selectAll()
        
        // AlarmScheduler -> AlarmDataStore.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.updateOnceNotificationActive(sender:)),
                                               name: .AlarmSchedulerNotificationDidDelivered,
                                               object: nil)
    }
    
    func awake() {}
    
    // MARK: - Handler.
    /// 반복이 없는 알람이 울렸을 때 해당 알람의 isActive를 false로 변경한다.
    ///
    /// 이 메서드는 한번만 울리게 되어있는 notification의 상태가 변화(알람이 울림)가 일어날 때 불릴 것이다.
    ///
    /// 알람 스케줄러는 필요할 때 마다 남아있는 notifications을 분석하여 AlarmSchedulerNotificationDidDelivered를 포스트한다.
    /// 알람 스케줄러는 앱이 foreground상태(WillPresentNotification)일 때와,
    ///             앱이 foreground상태가 될 때(didEndForeground)가 될 때 notification들을 분석한다.
    ///
    /// - Parameter sender: User notifications 상태를 분석하여 변경된 사항이 있는 alarm 리스트를 담아 보낸 notification.
    @objc private func updateOnceNotificationActive(sender: Notification) {
        
        guard let inActiveAlarms = sender.userInfo?[AlarmNotificationUserInfoKey.alarms] as? [Alarm] else { return }
        
        var shouldNotificationUpdate = false
        
        for inActiveAlarm in inActiveAlarms {
            guard inActiveAlarm.isActive == true else { continue }
            
            inActiveAlarm.isActive = false
            self.updateAlarm(alarm: inActiveAlarm)
            
            shouldNotificationUpdate = true
        }
        // Alarm에 변화가 있었다면 AlarmDataStoreDidUpdateAlarm를 포스트하여 AlarmScheduler에게 알려준다.
        if shouldNotificationUpdate {
            NotificationCenter.default.post(name: Notification.Name.AlarmDataStoreDidUpdateAlarm, object: nil)
        }
    }

    // MARK: - Methods.
    // - Private.
    /// 필요하다면 SQLite에서 알람테이블을 마이그레이션한다.
    static private func migarationIfNeeded(){

        AlarmDataStore.createTable()
        
        if DBManager.shared.db.user_version == 0 {
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
    
    /// 알람 테이블을 생성한다.
    ///
    /// 테이블이 생성될 필요가 있는지 없는지는 ifNotExists인자를 통해서 SQLite라이브러리에게 맡긴다.
    static private func createTable(){
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
    
    // - Internal.
    /// Notification은 생성될 때 identifier가 해당 알람의 ID에 문자을 추가(!,@,#)하여 생성된다.
    /// Notification의 Identifier가 해당 알람 identifier로 시작하는 것이 있으면 반환한다.
    /// 일치하는 알람이 없을 경우 nil이 반환된다.
    ///
    /// - Parameter identifier: alarm 객체를 찾는데 활용되는 notification identifier.
    /// - Returns: 메모리에 로드된 알람 인스턴스들 중 해당 identifier로 시작하는 알람이 반환된다.
    func alarm(withNotificationIdentifier identifier: String) -> Alarm? {
        let alarm = self.alarms.filter { identifier.hasPrefix($0.id) }
        return alarm.first
    }
    
    /// SQLite DB에 Alarm Table에 있는 모든 row를 불러와 Alarm 배열을 반환한다.
    ///
    /// 앱이 실행될 때 AlarmDataStore의 이니셜라이저에서 한번 로드된다.
    ///
    /// - Returns: SQLite DB에서 메모리로 불려와진 Alarm 배열.
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
    
    /// 알람 테이블과 alarm배열에 알람을 추가한다.
    ///
    /// AlarmDataStoreDidAddAlarm과 AlarmDataStoreDidChange를 포스트한다. 
    /// AlarmScheduler, AlarmListViewController가 각각의 옵저버이다.
    ///
    /// - Parameter alarm: DB와 alarms배열에 추가될 알람 인스턴스.
    func insertAlarm(alarm: Alarm) {
        // 메모리.
        self.alarms.append(alarm)
        
        // DB.
        let insert = AlarmTable.table.insert(AlarmTable.Column.id <- alarm.id,
                                             AlarmTable.Column.name <- alarm.name,
                                             AlarmTable.Column.date <- alarm.date,
                                             AlarmTable.Column.weekday <- alarm.weekday,
                                             AlarmTable.Column.sound <- alarm.sound,
                                             AlarmTable.Column.isActive <- alarm.isActive,
                                             AlarmTable.Column.isSnooze <- alarm.isSnooze)
        let result = manager.insertRow(insert: insert)
        // 결과 처리.
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
    
    /// 알람 테이블에 알람을 업데이트한다.
    ///
    /// AlarmDataStoreDidAddAlarm과 AlarmDataStoreDidChange를 포스트한다.
    /// AlarmScheduler, AlarmListViewController가 각각의 옵저버이다.
    ///
    /// 업데이트의 경우 메모리에 올라가 있는 알람 배열은 UIListViewController에서도 같은 것을 참조하여 변경하였기 때문에 따로 수정할 필요가 없다.
    ///
    /// - Parameter alarm: DB에 업데이트될 알람 인스턴스.
    func updateAlarm(alarm: Alarm) {
        // DB.
        let updateRow = AlarmTable.table.filter(AlarmTable.Column.id == alarm.id)
        let result = self.manager.updateRow(update: updateRow.update(AlarmTable.Column.id <- alarm.id,
                                                                     AlarmTable.Column.name <- alarm.name,
                                                                     AlarmTable.Column.date <- alarm.date,
                                                                     AlarmTable.Column.weekday <- alarm.weekday,
                                                                     AlarmTable.Column.sound <- alarm.sound,
                                                                     AlarmTable.Column.isActive <- alarm.isActive,
                                                                     AlarmTable.Column.isSnooze <- alarm.isSnooze))
        // 결과 처리.
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
    
    /// 알람 테이블과 alarm배열에 알람을 삭제한다.
    ///
    /// AlarmDataStoreDidAddAlarm과 AlarmDataStoreDidChange를 포스트한다.
    /// AlarmScheduler, AlarmListViewController가 각각의 옵저버이다.
    ///
    /// - Parameter alarm: DB와 alarms배열에 삭제될 알람 인스턴스.
    func deleteAlarm(alarm: Alarm) {
        // 메모리.
        guard let row = self.alarms.index(of: alarm) else { return }
        self.alarms.remove(at: row)
        
        // DB.
        let deletingRow = AlarmTable.table.filter(AlarmTable.Column.id == alarm.id)
        let result = self.manager.deleteRow(delete: deletingRow.delete())
        
        // 결과 처리.
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

//
//  AlarmDataStoreTests.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 27..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import XCTest
@testable import DreamRecorder
import UserNotifications

class AlarmDataStoreTests: XCTestCase {
    
    func testAlarmCRUD() {
        self.clearAlarms()
        self.insertAlarm()
        self.updateAlarm()
        self.deleteAlarm()
        self.receiveNotification()
    }
    
    func clearAlarms() {
        AlarmDataStore.shared.awake()
        for alarm in AlarmDataStore.shared.alarms {
            AlarmDataStore.shared.deleteAlarm(alarm: alarm)
        }
    }
    
    func insertAlarm() {
        /// Given
        let newAlarm = Alarm()
        
        /// When
        AlarmDataStore.shared.insertAlarm(alarm: newAlarm)
        let newAlarms = AlarmDataStore.shared.alarms
        
        /// Then
        XCTAssertEqual(newAlarms.count, 1)
    }
    
    func updateAlarm() {
        /// Given
        AlarmDataStore.shared.awake()
        let newSound = "Alarm-tone.wav"
        if let alarm = AlarmDataStore.shared.alarms.first {
            alarm.sound = newSound
            AlarmDataStore.shared.updateAlarm(alarm: alarm)
        }
        
        /// When
        if let updatedAlarm = AlarmDataStore.shared.alarms.last {
            /// Then
            XCTAssertEqual(updatedAlarm.sound, newSound)
        }
    }
    
    func deleteAlarm() {
        /// Given
        AlarmDataStore.shared.awake()
        let alarms = AlarmDataStore.shared.alarms
        if let alarm = AlarmDataStore.shared.alarms.first {
            AlarmDataStore.shared.deleteAlarm(alarm: alarm)
        }
        
        /// When
        let newAlarms = AlarmDataStore.shared.alarms
        
        /// Then
        XCTAssertEqual(newAlarms.count, (alarms.count == 0) ? 0 : alarms.count - 1)
    }
    
    func receiveNotification() {
        /// Given
        /// 알람이 생성되거나, isActive가 false에서 true가 되거나, 알람이 삭제가 되었을 때 각각의 메서드들이 노티피케이션 포스트.
        
        let newAlarm = Alarm()
        let ex = XCTestExpectation(description: "removeNotification")
        
        AlarmDataStore.shared.awake()
        AlarmScheduler.shared.awake()
        
        AlarmDataStore.shared.insertAlarm(alarm: newAlarm)

        let alertingAlarm = newAlarm
        
        if alertingAlarm.weekday == .none {
            alertingAlarm.isActive = false
        }
        AlarmDataStore.shared.updateAlarm(alarm: alertingAlarm)
        
        XCTAssertEqual(newAlarm.isActive, false)
        ex.fulfill()
    }
}

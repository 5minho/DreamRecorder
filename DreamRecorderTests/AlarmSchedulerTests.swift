//
//  AlarmSchedulerTests.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 26..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import XCTest
@testable import DreamRecorder
import UserNotifications

class AlarmSchedulerTests: XCTestCase {
    
    func testCreatAlarm() {
        
        /// 기존 데이터 초기화.
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        
        /// 더미생성.
        let newAlarm = Alarm()
        
        /// 반복없는 알람 생성 / 수정 / 삭제.
        self.createOnceAlarm(alarm: newAlarm, count: 1)
        self.updateOnceAlarm(alarm: newAlarm)
        self.deleteOnceAlarm(alarm: newAlarm)
        
        /// 평일반복 알람 생성 / 수정 / 삭제.
        newAlarm.weekday = [.mon, .tue, .wed]
        self.createOnceAlarm(alarm: newAlarm, count: 3)
        //        self.updateOnceAlarm(alarm: newAlarm)
        //        self.deleteOnceAlarm(alarm: newAlarm)
        
        /// 스누즈 알람 생성 / 삭제.
        self.createSnooze(alarm: newAlarm)
        self.removeSnooze(alarm: newAlarm)
        
        /// 지속적인 알람을 위한 알람 Duplicate.
//        self.duplicateAlarm(alarm: newAlarm)
    }
    
    func createOnceAlarm(alarm: Alarm, count: Int) {
        NotificationCenter.default.post(name: .AlarmDataStoreDidAddAlarm,
                                        object: nil,
                                        userInfo: [AlarmNotificationUserInfoKey.alarm: alarm])
        
        let ex = expectation(description: "createdNotificationCount")
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            XCTAssertEqual(requests.count, count)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 3)
    }
    
    func updateOnceAlarm(alarm: Alarm) {
        NotificationCenter.default.post(name: .AlarmDataStoreDidUpdateAlarm,
                                        object: nil,
                                        userInfo: [AlarmNotificationUserInfoKey.alarm: alarm])
        let ex = expectation(description: "updatedNotificationCount")
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            XCTAssertEqual(requests.count, 1)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 3)
    }

    func deleteOnceAlarm(alarm: Alarm) {
        NotificationCenter.default.post(name: .AlarmDataStoreDidDeleteAlarm,
                                        object: nil,
                                        userInfo: [AlarmNotificationUserInfoKey.alarm: alarm])
        var count = 0
        let exForWait = expectation(description: "waitExpectation")
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
            if count == 0 {
                count += 1
            } else {
                exForWait.fulfill()
                timer.invalidate()
            }
        }
        wait(for: [exForWait], timeout: 6)
        let ex = expectation(description: "deletedNotificationCount")
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            XCTAssertEqual(requests.count, 0)
            ex.fulfill()
        }
        wait(for: [ex], timeout: 3)
    }
    func createSnooze(alarm: Alarm) {
        AlarmScheduler.shared.createSnoozeNotification(for: alarm)
    }
    
    func removeSnooze(alarm: Alarm) {
        let ex = expectation(description: "removeSnooze")
        AlarmScheduler.shared.removeSnoozeNotification(for: alarm) { 
            ex.fulfill()
        }
        wait(for: [ex], timeout: 3)
    }
}

//
//  AlarmSoundTests.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 25..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//


import XCTest
@testable import DreamRecorder
import UserNotifications

class AlarmSoundTests: XCTestCase {
    
    func testAlarmSoundSetup() {
        SoundManager.shared.awake()
//        self.invokeAlarmSound()
        self.playAlarmSound()
    }
    
    func invokeAlarmSound() {
        /// Given
        SoundManager.shared.awake()
        // 다음 노티피케이션이 생기도록 더미를 만든다.
        let newAlarm = Alarm()
        var now = Date()
        
        /// When
        NotificationCenter.default.post(name: Notification.Name.AlarmSchedulerNextNotificationDateDidChange,
                                        object: nil,
                                        userInfo: [AlarmNotificationUserInfoKey.alarm: newAlarm,
                                                   AlarmNotificationUserInfoKey.nextTriggerDate: now.addTimeInterval(60)])
        /// Then
//        XCTAssertNotNil(SoundManager.shared.nextAlarm)
    }
    
    func playAlarmSound() {
        /// Given
        let ex = expectation(description: "HelloWorld")
        // 다음 노티피케이션이 생기도록 더미를 만든다.
        let newAlarm = Alarm()
        let now = Date()
        /// When
        NotificationCenter.default.post(name: .AlarmSchedulerNextNotificationDateDidChange,
                                        object: nil,
                                        userInfo: [AlarmNotificationUserInfoKey.alarm: newAlarm,
                                                   AlarmNotificationUserInfoKey.nextTriggerDate: now.addingTimeInterval(2)])
        /// Then
        var count = 0
        Timer.scheduledTimer(withTimeInterval: 3, repeats: true) { (timer) in
            if count == 0 {
                count += 1
            } else {
                ex.fulfill()
            }
            
        }
        wait(for: [ex], timeout: 7)
        XCTAssertTrue(SoundManager.shared.isPlayingAlarm)
        self.puaseAlarmSound()
    }
    
    func puaseAlarmSound() {
        SoundManager.shared.pauseAlarm()
    }
}

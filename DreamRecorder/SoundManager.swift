//
//  SoundManager.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 15..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit
import AVFoundation
import UserNotifications

extension UILocalNotification: Comparable {
    
    public static func <(lhs: UILocalNotification, rhs: UILocalNotification) -> Bool {
        guard let leftFireDate = lhs.fireDate else { return false }
        guard let rightFireDate = rhs.fireDate else { return false }
        
        return (leftFireDate.compare(rightFireDate) == .orderedDescending)
    }
    
    public static func <=(lhs: UILocalNotification, rhs: UILocalNotification) -> Bool {
        guard let leftFireDate = lhs.fireDate else { return false }
        guard let rightFireDate = rhs.fireDate else { return false }
        
        return (leftFireDate.compare(rightFireDate) == .orderedDescending) ||
                (leftFireDate.compare(rightFireDate) == .orderedSame)
    }

    public static func >=(lhs: UILocalNotification, rhs: UILocalNotification) -> Bool {
        guard let leftFireDate = lhs.fireDate else { return false }
        guard let rightFireDate = rhs.fireDate else { return false }
        
        return (leftFireDate.compare(rightFireDate) == .orderedAscending) ||
                (leftFireDate.compare(rightFireDate) == .orderedSame)
    }

    public static func >(lhs: UILocalNotification, rhs: UILocalNotification) -> Bool {
        guard let leftFireDate = lhs.fireDate else { return false }
        guard let rightFireDate = rhs.fireDate else { return false }
        
        return (leftFireDate.compare(rightFireDate) == .orderedAscending)
    }
}

@available(iOS 10.0, *)
extension UNNotificationRequest: Comparable {
    
    public static func <(lhs: UNNotificationRequest, rhs: UNNotificationRequest) -> Bool {
        guard let leftTrigger = lhs.trigger as? UNCalendarNotificationTrigger else { return false }
        guard let rightTrigger = rhs.trigger as? UNCalendarNotificationTrigger else { return false }
        guard let leftTriggerDate = leftTrigger.nextTriggerDate() else { return false }
        guard let rightTriggerDate = rightTrigger.nextTriggerDate() else { return false }
        
        return (leftTriggerDate.compare(rightTriggerDate) == .orderedDescending)
    }

    public static func <=(lhs: UNNotificationRequest, rhs: UNNotificationRequest) -> Bool {
        guard let leftTrigger = lhs.trigger as? UNCalendarNotificationTrigger else { return false }
        guard let rightTrigger = rhs.trigger as? UNCalendarNotificationTrigger else { return false }
        guard let leftTriggerDate = leftTrigger.nextTriggerDate() else { return false }
        guard let rightTriggerDate = rightTrigger.nextTriggerDate() else { return false }
        
        return (leftTriggerDate.compare(rightTriggerDate) == .orderedDescending) ||
                (leftTriggerDate.compare(rightTriggerDate) == .orderedSame)
    }

    public static func >=(lhs: UNNotificationRequest, rhs: UNNotificationRequest) -> Bool {
        guard let leftTrigger = lhs.trigger as? UNCalendarNotificationTrigger else { return false }
        guard let rightTrigger = rhs.trigger as? UNCalendarNotificationTrigger else { return false }
        guard let leftTriggerDate = leftTrigger.nextTriggerDate() else { return false }
        guard let rightTriggerDate = rightTrigger.nextTriggerDate() else { return false }
        
        return (leftTriggerDate.compare(rightTriggerDate) == .orderedAscending) ||
                (leftTriggerDate.compare(rightTriggerDate) == .orderedSame)
    }
    
    public static func >(lhs: UNNotificationRequest, rhs: UNNotificationRequest) -> Bool {
        guard let leftTrigger = lhs.trigger as? UNCalendarNotificationTrigger else { return false }
        guard let rightTrigger = rhs.trigger as? UNCalendarNotificationTrigger else { return false }
        guard let leftTriggerDate = leftTrigger.nextTriggerDate() else { return false }
        guard let rightTriggerDate = rightTrigger.nextTriggerDate() else { return false }
        
        return (leftTriggerDate.compare(rightTriggerDate) == .orderedAscending)
    }
}

extension Notification.Name {
    static let SoundManagerDidPlayAlarmToEnd = Notification.Name("SoundManagerDidPlayAlarmToEnd")
}

class SoundManager {
    // Singleton Property.
    static let shared: SoundManager = SoundManager()

    // AVFoundation Property.
    var queuePlayer: AVQueuePlayer?
    
    var nextTriggerDate: Date?
    
    func awake(){
        
    }
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleAlarmSchedulerNextNotificationDateDidChange(sender:)),
                                               name: Notification.Name.AlarmSchedulerNextNotificationDateDidChange,
                                               object: nil)
        
        self.registerBackgroundSoundToAlarm(withSoundName: "Alarm-tone")
    }
    
    @objc func handleAlarmSchedulerNextNotificationDateDidChange(sender: Notification) {
        
        guard let alarm = sender.userInfo?["alarm"] as? Alarm else { return }
        self.nextTriggerDate = sender.userInfo?["nextDate"] as? Date
        
        self.updateAlarmSound(withSoundName: alarm.sound)
    }
    
    func playAlarmSoundIfNeeded(playerItem: AVPlayerItem){
        print("Sound Item Did End")
        playerItem.seek(to: kCMTimeZero)
        if let nextTriggerDate = self.nextTriggerDate {
            print("\(nextTriggerDate) compared \(Date().addingTimeInterval(3))")
            if nextTriggerDate.compare(Date().addingTimeInterval(3)) == .orderedAscending {
                self.queuePlayer?.advanceToNextItem()
                print("Play Next Music")
            }
        }
    }
    
    @objc func playerItemDidPlayToEndTime(sender notification: Notification) {
        guard let item = notification.object as? AVPlayerItem else { return }
        self.playAlarmSoundIfNeeded(playerItem: item)
    }
    
    func registerBackgroundSoundToAlarm(withSoundName soundName: String){
        
        guard let silentSoundPath = Bundle.main.path(forResource: "mute", ofType: "mp3") else { return }
        guard let alarmSoundPath = Bundle.main.path(forResource: soundName, ofType: "wav") else { return }
        
        let silentSoundURL = URL(fileURLWithPath: silentSoundPath)
        let alarmSoundURL = URL(fileURLWithPath: alarmSoundPath)
        
        let silentPlayerItem = AVPlayerItem(url: silentSoundURL)
        let alarmPlayerItem = AVPlayerItem(url: alarmSoundURL)
        
        self.queuePlayer = AVQueuePlayer(items: [silentPlayerItem, alarmPlayerItem])
        self.queuePlayer?.actionAtItemEnd = .none
        self.queuePlayer?.volume = 1
        
        self.queuePlayer?.play()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playerItemDidPlayToEndTime(sender:)),
                                               name: Notification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: self.queuePlayer?.currentItem)
    }
    
    func updateAlarmSound(withSoundName soundName: String) {
        
        guard let silentSoundPath = Bundle.main.path(forResource: "mute", ofType: "mp3") else { return }
        guard let alarmSoundPath = Bundle.main.path(forResource: soundName, ofType: "wav") else { return }
        
        let silentSoundURL = URL(fileURLWithPath: silentSoundPath)
        let alarmSoundURL = URL(fileURLWithPath: alarmSoundPath)
        
        let silentPlayerItem = AVPlayerItem(url: silentSoundURL)
        let alarmPlayerItem = AVPlayerItem(url: alarmSoundURL)
        
        self.queuePlayer = AVQueuePlayer(items: [silentPlayerItem, alarmPlayerItem])
        self.queuePlayer?.actionAtItemEnd = .none
        self.queuePlayer?.volume = 1

        self.queuePlayer?.play()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playerItemDidPlayToEndTime(sender:)),
                                               name: Notification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: self.queuePlayer?.currentItem)
    }
    
    func pauseAlarm(){
        self.queuePlayer?.pause()
        NotificationCenter.default.post(name: Notification.Name.SoundManagerDidPlayAlarmToEnd, object: nil)
    }
}

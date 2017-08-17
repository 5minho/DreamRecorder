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

class SoundManager {
    
    // Singleton Property.
    static let shared: SoundManager = SoundManager()

    // AVFoundation Property.
    var queuePlayer: AVQueuePlayer?
    
    // Background.
    func nextTriggerDate(completionHandler completion: @escaping (Date?) -> Void) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                let ascendingNotifications = requests.sorted(by: > )
                if let calendarNotificationTrigger = ascendingNotifications.first?.trigger as? UNCalendarNotificationTrigger {
                    let nextTriggerDate = calendarNotificationTrigger.nextTriggerDate()
                    completion(nextTriggerDate)
                } else {
                    completion(nil)
                }
                
            })
        } else {
            guard let notifications = UIApplication.shared.scheduledLocalNotifications else { return completion(nil) }
            let ascendingNotifications = notifications.sorted(by: > )
            let nextTriggerDate = ascendingNotifications.first?.fireDate
            completion(nextTriggerDate)
        }
    }
    
    func playAlarmSoundIfNeeded(playerItem: AVPlayerItem){
        print("ifneeded")
        self.nextTriggerDate { (date) in
            guard let nextTriggeredDate = date else { return }
            print("\(nextTriggeredDate) compared \(Date().addingTimeInterval(60))")
            if nextTriggeredDate.compareByMinuteUnit(other: Date().addingTimeInterval(60)) {
                self.queuePlayer?.advanceToNextItem()
            } else {
                playerItem.seek(to: kCMTimeZero)
            }
        }
    }
    
    @objc func playerItemDidPlayToEndTime(sender notification: Notification) {
        guard let item = notification.object as? AVPlayerItem else { return }
        self.playAlarmSoundIfNeeded(playerItem: item)
    }
    
    func registerBackgroundSoundToAlarm(){
        
        guard let silentSoundPath = Bundle.main.path(forResource: "Spaceship_Alarm", ofType: "mp3") else { return }
        guard let alarmSoundPath = Bundle.main.path(forResource: "Carefree_Melody", ofType: "mp3") else { return }
        
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

    func playAlarmSound(name soundName: String) {
        
    }
}

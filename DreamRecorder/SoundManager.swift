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
import MediaPlayer

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
    var alarmPlayer: AVPlayer?
    
    var nextTriggerDate: Date?
    var nextAlarmURL: URL?
    
    func awake(){
        
    }
    
    init() {
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleAlarmSchedulerNextNotificationDateDidChange(sender:)),
                                               name: Notification.Name.AlarmSchedulerNextNotificationDateDidChange,
                                               object: nil)
    }
    
    @objc func handleAlarmSchedulerNextNotificationDateDidChange(sender: Notification) {
        
        guard let alarm = sender.userInfo?["alarm"] as? Alarm else { return }
        self.nextTriggerDate = sender.userInfo?["nextDate"] as? Date
        
        self.updateAlarmSound(withSoundPath: alarm.sound)
    }
    
    private func changeSystemVolumeToMax() {
        let volumeView = MPVolumeView()
        for view in volumeView.subviews {
            if (NSStringFromClass(view.classForCoder) == "MPVolumeSlider") {
                let slider = view as! UISlider
                slider.setValue(1, animated: false)
            }
        }
    }
    
    @objc func playAlarmSoundRepeatly(sender notification: Notification){
        guard let item = notification.object as? AVPlayerItem else { return }
        print("Repeatly")
        item.seek(to: kCMTimeZero)
    }
    
    func playAlarmSoundIfNeeded(playerItem: AVPlayerItem){
        print("Sound Item Did End")
        
        if let nextTriggerDate = self.nextTriggerDate {
            playerItem.seek(to: kCMTimeZero)
            print("\(nextTriggerDate) compared \(Date().addingTimeInterval(2))")
            if nextTriggerDate.compare(Date().addingTimeInterval(2)) != .orderedDescending {
//                self.changeSystemVolumeToMax()
                
                guard let url = self.nextAlarmURL else { return }
                if self.alarmPlayer == nil {
                    self.alarmPlayer = AVPlayer(url: url)
                    self.alarmPlayer?.play()
                    self.alarmPlayer?.actionAtItemEnd = .none
                    NotificationCenter.default.addObserver(self,
                                                           selector: #selector(self.playAlarmSoundRepeatly(sender:)),
                                                           name: Notification.Name.AVPlayerItemDidPlayToEndTime,
                                                           object: self.alarmPlayer?.currentItem)
                }
//                self.queuePlayer?.advanceToNextItem()
                
            }
        }
    }
    
    @objc func playerItemDidPlayToEndTime(sender notification: Notification) {
        guard let item = notification.object as? AVPlayerItem else { return }
        self.playAlarmSoundIfNeeded(playerItem: item)
    }
    
    func updateAlarmSound(withURL url: URL) {
        guard let silentSoundPath = Bundle.main.path(forResource: "mute", ofType: "mp3") else { return }
        let silentSoundURL = URL(fileURLWithPath: silentSoundPath)

        let silentPlayerItem = AVPlayerItem(url: silentSoundURL)
        self.nextAlarmURL = url
        
        self.queuePlayer = AVQueuePlayer(items: [silentPlayerItem])
        self.queuePlayer?.actionAtItemEnd = .none
        self.queuePlayer?.volume = 1
        
        self.queuePlayer?.play()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.playerItemDidPlayToEndTime(sender:)),
                                               name: Notification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: self.queuePlayer?.currentItem)
    }
    
    func updateAlarmSound(withSoundPath soundPath: String) {
        if soundPath.hasPrefix("ipod-library:") {
            if let alarmSoundURL = URL(string: soundPath) {
                self.updateAlarmSound(withURL: alarmSoundURL)
            } else {
                
            }
        } else {
            guard let fileFormat = soundPath.components(separatedBy: ".").last else { return }
            guard let path = Bundle.main.path(forResource: soundPath.soundTitle, ofType: fileFormat) else { return }
            self.updateAlarmSound(withURL: URL(fileURLWithPath: path))
        }
        
    }
    
    func pauseAlarm(){
        self.alarmPlayer = nil
        NotificationCenter.default.post(name: Notification.Name.SoundManagerDidPlayAlarmToEnd, object: nil)
    }
}

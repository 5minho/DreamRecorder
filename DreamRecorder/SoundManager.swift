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

    // Private Properties.
    private var queuePlayer: AVQueuePlayer?
    private var alarmPlayer: AVPlayer?
    private var previousVolume: Float
    private var nextTriggerDate: Date?
    
    // Internal Properties.
    var nextAlarm: Alarm?
    var isPlayingAlarm: Bool {
        return self.alarmPlayer != nil
    }
    
    func awake(){}
    
    // MARK: Initializer.
    init() {
        self.previousVolume = AVAudioSession.sharedInstance().outputVolume
//        NotificationCenter.default.addObserver(self,
//                                               selector: #selector(self.handleUIApplicationWillEnterForeground(sender:)),
//                                               name: Notification.Name.UIApplicationWillEnterForeground,
//                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleAlarmSchedulerNextNotificationDateDidChange(sender:)),
                                               name: Notification.Name.AlarmSchedulerNextNotificationDateDidChange,
                                               object: nil)
        self.setupQueuePlayerWithMuteSound()
    }
    
    // @abstract        Initializes an instance of AVQueuePlayer by enqueueing the mute sound file.
    // @discussion      This AVQueuePlayer make app run in background by playing repeatly mute sound file.
    private func setupQueuePlayerWithMuteSound() {
        guard let silentSoundPath = Bundle.main.path(forResource: "mute", ofType: "mp3") else { return }
        
        let silentSoundURL = URL(fileURLWithPath: silentSoundPath)
        let silentPlayerItem = AVPlayerItem(url: silentSoundURL)
        
        self.queuePlayer = AVQueuePlayer(items: [silentPlayerItem])
        self.queuePlayer?.actionAtItemEnd = .none
        self.queuePlayer?.volume = 1
        
        self.queuePlayer?.play()
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handlePlayerItemDidPlayToEndTime(sender:)),
                                               name: Notification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: self.queuePlayer?.currentItem)
    }
    
    // MARK: Handler.
    // @abstract        Handle AlarmScheduler Next Notification Date Did Change.
    // @discussion      Update alarm sound with sound path that alarm class have.
    //                  Check String extension about controling sound path.
    @objc func handleAlarmSchedulerNextNotificationDateDidChange(sender: Notification) {
        guard let alarm = sender.userInfo?[AlarmNotificationUserInfoKey.alarm] as? Alarm else { return }
        self.nextTriggerDate = sender.userInfo?[AlarmNotificationUserInfoKey.nextTriggerDate] as? Date
        self.nextAlarm = alarm
    }
    
    // @abstract        Play alarm sound repeatly.
    @objc func playAlarmSoundRepeatly(sender notification: Notification){
        guard let item = notification.object as? AVPlayerItem else { return }
        item.seek(to: kCMTimeZero)
    }
    
    // @abstract        Handler alarm sound player did end play item.
    @objc func handlePlayerItemDidPlayToEndTime(sender notification: Notification) {
        guard let item = notification.object as? AVPlayerItem else { return }
        self.playAlarmSoundIfNeeded(playerItem: item)
    }
    
    // @abstract        Play alarm sound if needed.
    // @discussion      This method is handler for AVPlayerItemDidPlayToEndTime notification.
    //                  Mute sound is alive at background and check should play alarm sound.
    func playAlarmSoundIfNeeded(playerItem: AVPlayerItem){
        print("Mute is alive")
        playerItem.seek(to: kCMTimeZero)
        
        if let nextTriggerDate = self.nextTriggerDate {
            print("=========================")
            print("\(nextTriggerDate)")
            print("\(Date().addingTimeInterval(2))")
            print("=========================")
            if nextTriggerDate.compare(Date().addingTimeInterval(2)) != .orderedDescending {
                //                self.changeSystemVolumeToMax()
                guard let url = self.nextAlarm?.sound.soundURL else { return }
                if self.alarmPlayer == nil {
                    self.alarmPlayer = AVPlayer(url: url)
                    self.alarmPlayer?.play()
                    self.alarmPlayer?.actionAtItemEnd = .none
                    NotificationCenter.default.addObserver(self,
                                                           selector: #selector(self.playAlarmSoundRepeatly(sender:)),
                                                           name: Notification.Name.AVPlayerItemDidPlayToEndTime,
                                                           object: self.alarmPlayer?.currentItem)
                }
            }
        }
    }
    
    // MARK: Methods
    // @abstract        Change system volume
    // @discussion      We can update system volume to play alarm sound loudly, even though user lower system volume.
    private func changeSystemVolume(to value: Float) {
        let volumeView = MPVolumeView()
        for view in volumeView.subviews {
            if (NSStringFromClass(view.classForCoder) == "MPVolumeSlider") {
                guard let slider = view as? UISlider else { continue }
                self.previousVolume = AVAudioSession.sharedInstance().outputVolume
                slider.setValue(value, animated: false)
            }
        }
    }
    
    // @abstract        Stop playing AVPlayer item.
    // @discussion      AVPlayer should be removed from NotificationCenter, Otherwise playAlarmSoundRepeatly will be called continuously.
    //                  And post SoundManagerDidPlayAlarmToEnd that might update next trigger date.
    func pauseAlarm(){
        NotificationCenter.default.removeObserver(self.queuePlayer as Any)
        self.alarmPlayer = nil
        self.changeSystemVolume(to: self.previousVolume)
        NotificationCenter.default.post(name: Notification.Name.SoundManagerDidPlayAlarmToEnd, object: nil)
    }
}

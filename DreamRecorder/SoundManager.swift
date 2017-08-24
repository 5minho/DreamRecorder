//
//  SoundManager.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 15..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

extension Notification.Name {
    static let SoundManagerAlarmPlayerDidEnd = Notification.Name("SoundManagerAlarmPlayerDidEnd")
    static let SoundManagerAlarmPlayerDidStart = Notification.Name("SoundManagerAlarmPlayerDidStart")
}

class SoundManager: NSObject {
    
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
    override init() {
        
        previousVolume = AVAudioSession.sharedInstance().outputVolume
        
        super.init()
        
        self.setupQueuePlayerToPlayMuteSound()
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AlarmSchedulerNextNotificationDateDidChange,
                                               object: nil,
                                               queue: OperationQueue.main)
        { (notification) in
            /// AlarmScheduler가 다음에 울릴 알림이 바뀐 것을 알리면 실행된다.
            /// AlarmScheduler는 UserInfo에 다음에 울릴 알람 객체와 TriggerDate를 가지고 있다.
            /// SoundManager는 다음에 울릴 시간과 소리 파일명만 알면 된다.
            /// 소리 파일 접근은 String 익스텐션에서 확인할 수 있다.
            let nextAlarm = notification.userInfo?[AlarmNotificationUserInfoKey.alarm] as? Alarm
            self.nextTriggerDate = notification.userInfo?[AlarmNotificationUserInfoKey.nextTriggerDate] as? Date
            self.nextAlarm = nextAlarm
        }
    }

    /// Mute 사운드 파일을 큐 목록에 추가하여 AVQueuePlayer의 인스턴스를 초기화한다
    /// AVQueuePlayer가 지속적으로 Mute 사운드 파일을 재생시킴으로써 앱이 백그라운드 상태에서 동작하도록 만든다.
    private func setupQueuePlayerToPlayMuteSound() {
        
        guard let silentSoundPath = Bundle.main.path(forResource: "mute", ofType: "mp3") else { return }
        
        let silentSoundURL = URL(fileURLWithPath: silentSoundPath)
        let silentPlayerItem = AVPlayerItem(url: silentSoundURL)
        
        self.queuePlayer = AVQueuePlayer(items: [silentPlayerItem])
        self.queuePlayer?.actionAtItemEnd = .none
        self.queuePlayer?.volume = 1
        
        self.queuePlayer?.play()
        
        NotificationCenter.default.addObserver(forName: Notification.Name.AVPlayerItemDidPlayToEndTime,
                                               object: self.queuePlayer?.currentItem,
                                               queue: OperationQueue.main)
        {   (notification) in
            /// 뮤트 사운드 파일이 끝났으면 다시 재생시킨다.
            guard let item = notification.object as? AVPlayerItem else { return }
            self.playAlarmSoundIfNeeded(playerItem: item)
        }
    }
    
    

    /// 알람시간에 도달하면 알람음을 재생한다.
    /// AVPlayerItemDidPlayToEndTime 노티피케이션의 핸들러다.
    /// Mute사운드가 계속해서(3초 간격으로) 반복되서 Background상태를 유지할 수 있다.
    /// 현재시간이 nextTriggerDate에 도달하면 설정된 알람(self.nextAlarm)이 가지고 있는 사운드를 재생힌다.
    ///
    /// - Parameter playerItem: Mute 사운드 플레이어 아이템.
    func playAlarmSoundIfNeeded(playerItem: AVPlayerItem){
        
        playerItem.seek(to: kCMTimeZero)
        
        if let nextTriggerDate = self.nextTriggerDate {
            print("=========================")
            print("\(nextTriggerDate)")
            print("\(Date().addingTimeInterval(2))")
            print("=========================")
            
            if nextTriggerDate.compare(Date().addingTimeInterval(2)) != .orderedDescending {
                
                self.changeSystemVolume(to: 1)
                
                guard let url = self.nextAlarm?.sound.soundURL else { return }
                if self.alarmPlayer == nil {
                    self.alarmPlayer = AVPlayer(url: url)
                    self.alarmPlayer?.volume = 0.1
                    self.alarmPlayer?.play()
                    self.fadeInAlarmPlayerSound()
                    self.alarmPlayer?.actionAtItemEnd = .none
                    
                    NotificationCenter.default.post(name: Notification.Name.SoundManagerAlarmPlayerDidEnd, object: nil)
                    
                    NotificationCenter.default.addObserver(forName: Notification.Name.AVPlayerItemDidPlayToEndTime,
                                                           object: self.alarmPlayer?.currentItem,
                                                           queue: OperationQueue.main)
                    {   (notification) in
                        /// Play alarm sound repeatly.
                        guard let item = notification.object as? AVPlayerItem else { return }
                        item.seek(to: kCMTimeZero)
                    }
                }
            }
        }
    }
    
    /// 시스템 소리 크기를 변경한다.
    /// 사용자의 시스템 볼륨을 낮춰놧을 경우를 대비하여 알람음이 울릴때는 시스템 볼륨 크기를 최대(1)로 설정한다.
    /// 알람이 종료될 때에는 알람음이 울리기 전의 소리 크기(self.previousVolume)으로 설정한다.
    ///
    /// - Parameter value: 시스템 볼륨 크기로 설정할 값.
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
    
    
    /// AVPlayer의 Volume을 0.1초 간격으로 0.01씩 증가시켜 최대(1)에 도달하게 만듭니다.
    @objc private func fadeInAlarmPlayerSound() {
        
        guard let playingAlarmPlayer = self.alarmPlayer,
            playingAlarmPlayer.volume < 1
        else {
            return
        }
        self.alarmPlayer?.volume += 0.01
        self.perform(#selector(self.fadeInAlarmPlayerSound), with: nil, afterDelay: 0.1)
    }
    
    /**
        알람음을 중지시킨다.
     
        AVPlayer should be removed from NotificationCenter, Otherwise playAlarmSoundRepeatly will be called continuously.
        post SoundManagerDidPlayAlarmToEnd that might update next trigger date.
     **/
    func pauseAlarm(){
        
        // iOS9 이상부터 deinit될 때 removeObserver를 부를 필요가 없어졌다.
        //NotificationCenter.default.removeObserver(self.alarmPlayer as Any)
        
        self.alarmPlayer = nil
        self.changeSystemVolume(to: self.previousVolume)
        NotificationCenter.default.post(name: Notification.Name.SoundManagerAlarmPlayerDidEnd, object: nil)
    }
}

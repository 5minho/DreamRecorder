//
//  AlarmScheduler.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 8..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import Foundation
import UserNotifications
import UIKit

extension AlarmNotificationUserInfoKey {
    static let identifier = "identifier"
}

struct AlarmIdentifier {
    /// UserNotification에 활용 될 CategoryIdentifier.
    struct NotificationCategory {
        static let snooze = "SnoozeLocalNotificationCategory"
        static let once = "OnceLocalNotificationCategory"
    }
    /// UserNotification에 활용 될 ActionIdentifier.
    struct NotificationAction {
        static let snooze = "SnoozeNotificationAction"
        static let stop = "StopNotificationAction"
    }
}

extension Notification.Name {
    // AlarmScheduler -> AlarmDataStore.
    /// 만약 Delivered된 UserNotification이 존재할 경우 포스트한다.
    /// 해당 Notification은 UserNotification과 연관된 alarm 인스턴스를 userInfo를 통해 전달한다.
    /// userInfo에서 AlarmNotificationUserInfoKey를 통해 alarm 인스턴스에 접근할 수 있다.
    static let AlarmSchedulerNotificationDidDelivered = Notification.Name("AlarmSchedulerNotificationDidDelivered")
    
    // AlarmScheduler -> SoundManager.
    /// 만약 Notification에 변화가 생겨서 다음에 울릴 알람시간이 변경된 경우 포스트한다.
    static let AlarmSchedulerNextNotificationDateDidChange = Notification.Name("AlarmSchedulerNextNotificationDateDidChange")
}

class AlarmScheduler {
    
    // MARK: - Properties.
    // - Singleton.
    static let shared: AlarmScheduler = AlarmScheduler()
    
    // MARK: - Initializer.
    init() {
        // UserNotification의 액션과 카테고리를 설정한다.
        self.setupNotificationSetting()
        //
        self.updateNotificationsIfNeeded()
        self.postNextNotificationDateDidChangeIfNeeded()
        
        // AlarmDataStore -> AlarmScheduler.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleAlarmDataStoreDidAddAlarm(sender:)),
                                               name: .AlarmDataStoreDidAddAlarm,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleAlarmDataStoreDidUpdateAlarm(sender:)),
                                               name: .AlarmDataStoreDidUpdateAlarm,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleAlarmDataStoreDidDeleteAlarm(sender:)),
                                               name: .AlarmDataStoreDidDeleteAlarm,
                                               object: nil)
        
        // SoundManager -> AlarmScheduler.
        NotificationCenter.default.addObserver(forName: .SoundManagerAlarmPlayerDidEnd,
                                               object: nil,
                                               queue: .main)
        { (notification) in
            self.postNextNotificationDateDidChangeIfNeeded()
        }
        
        // UIApplication -> AlarmScheduler.
        
        NotificationCenter.default.addObserver(forName: .UIApplicationWillEnterForeground,
                                               object: nil,
                                               queue: .main)
        { (notification) in
            self.updateNotificationsIfNeeded()
            self.postNextNotificationDateDidChangeIfNeeded()
        }
    }
    
    func awake() {}
    
    // MARK: - Handler.
    // from AlarmDataStore.
    @objc private func handleAlarmDataStoreDidAddAlarm(sender: Notification) {
        
        guard let alarm = sender.userInfo?[AlarmNotificationUserInfoKey.alarm] as? Alarm else { return }
        
        self.addNotification(with: alarm)
        self.postNextNotificationDateDidChangeIfNeeded()
    }
    
    @objc private func handleAlarmDataStoreDidUpdateAlarm(sender: Notification) {
        
        guard let alarm = sender.userInfo?[AlarmNotificationUserInfoKey.alarm] as? Alarm else { return }
        
        if alarm.isActive {
            self.updateNotification(with: alarm)
        } else {
            self.deleteNotification(with: alarm, completionBlock: {
                self.postNextNotificationDateDidChangeIfNeeded()
            })
        }
    }
    
    @objc private func handleAlarmDataStoreDidDeleteAlarm(sender: Notification) {
        
        guard let alarm = sender.userInfo?[AlarmNotificationUserInfoKey.alarm] as? Alarm else { return }
        
        self.deleteNotification(with: alarm, completionBlock: {
            self.postNextNotificationDateDidChangeIfNeeded()
        })
    }
    
    /// 대기중인 UserNotification들을 확인하여 업데이트 필요한지 확인 후 업데이트한다.
    ///
    /// 앱이 foreground 상태 진입시 마다 (초기 실행 or Foreground진입)시에 불린다.
    private func updateNotificationsIfNeeded() {
        if #available(iOS 10.0, *) {
            // 앱이 꺼질 것을 대비하여 여려개 생성해놓은 아직 남아있는 Notification들을 삭제한다.
            // Foreground 상태가 되면 AVPlayer를 통해 알람음을 재생하므로 더 이상 Notification을 통해서 알릴 필요가 없어지기 때문이다.
            // 앱이 Terminate되어서 duplicate되었는데 몇 번째의 Notification을 받은 상태로 앱을 실행했는지 알 수 없으므로.
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
            UNUserNotificationCenter.current().getPendingNotificationRequests {
                
                (pendingNotificationRequests) in
                
                /// 복제 노티피케이션을 삭제한다.
                DispatchQueue.main.async {
                    var duplicatedRequestIdentifiers: [String] = []
                    
                    for request in pendingNotificationRequests {
                        guard request.identifier.contains("#") else { continue }
                        duplicatedRequestIdentifiers.append(request.identifier)
                    }
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: duplicatedRequestIdentifiers)
                    print("notifications is removed (count: \(duplicatedRequestIdentifiers.count))")
                    
                    /// 스누즈 노티피케이션을 삭제한다.
                    var snoozeRequests: [String] = []
                    
                    for request in pendingNotificationRequests {
                        guard request.identifier.hasSuffix("@") else { continue }
                        snoozeRequests.append(request.identifier)
                    }
                    
                    if snoozeRequests.isEmpty == false {
                        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: snoozeRequests)
                    }
                    
                    UNUserNotificationCenter.current().getPendingNotificationRequests {
                        
                        (pendingNotificationRequests) in
                        
                        // 알람 객체는 있으나 Notification이 없는 객체는 alarm.isActive를 false로 바꾸어 주어야함.
                        let inActiveAlarms = AlarmDataStore.shared.alarms.filter({ (alarm) -> Bool in
                            
                            var notificationNotExist = true
                            
                            for request in pendingNotificationRequests {
                                guard request.identifier.hasPrefix(alarm.id) else { continue }
                                notificationNotExist = false
                                break
                            }
                            
                            return notificationNotExist
                        })
                        
                        guard inActiveAlarms.isEmpty == false else { return }
                        
                        NotificationCenter.default.post(name: .AlarmSchedulerNotificationDidDelivered,
                                                        object: nil,
                                                        userInfo: [AlarmNotificationUserInfoKey.alarms: inActiveAlarms])
                        
                    }
                }
            }
            
            // Alarm 목록중에 Notifiation을 가지고 있지 않은 Alarm은 Inactivate해주어야 한다.
            // 사용자가 반복이 없는 알람을 설정해 놓았을 경우 해당 알람 시간이 지난 후 라면 비활성화 하여야한다.
            // 앱 실행단계(Scheduler Initializer), background에서 foreground진입단계, present단계에서 호출한다.
            // TODO: DidReceive는 foreground가 대체하므로 필요 없을 것.
//            UNUserNotificationCenter.current().getPendingNotificationRequests {
//                
//                
//            }
        } else {
            
            guard let notifications = UIApplication.shared.scheduledLocalNotifications else { return }
            
            // 중복알람을 위한 노티피케이션을 삭제한다.
            // 그리고 스누즈 노트피케이션도 삭제한다.
            for notification in notifications {
                guard let notificationIdentifier = notification.userInfo?[AlarmNotificationUserInfoKey.identifier] as? String else { continue }
                if notificationIdentifier.hasSuffix("#") ||
                    notificationIdentifier.hasSuffix("@") {
                    UIApplication.shared.cancelLocalNotification(notification)
                }
            }
            
            // 알람 객체는 있으나 Notification이 없는 객체는 alarm.isActive를 false로 바꾸어 주어야함.
            let inActiveAlarms = AlarmDataStore.shared.alarms.filter({ (alarm) -> Bool in
                var isDelivered = true
                for notification in notifications {
                    guard let identifier = notification.userInfo?[AlarmNotificationUserInfoKey.identifier] as? String else { continue }
                    if identifier.contains(alarm.id) {
                        isDelivered = false
                        break
                    }
                }
                return isDelivered
            })
            
            if inActiveAlarms.count > 0 {
                NotificationCenter.default.post(name: Notification.Name.AlarmSchedulerNotificationDidDelivered,
                                                object: nil,
                                                userInfo: [AlarmNotificationUserInfoKey.alarms: inActiveAlarms])
            }
        }
    }

    // MARK: - Methods.
    /// Notification들의 triggerDate를 비교하여 다음에 울릴 알람 시간과 nextTriggerDate를 통해 AlarmSchedulerNextNotificationDateDidChange를 포스트한다.
    private func postNextNotificationDateDidChangeIfNeeded(){
        
        self.nextTriggerDate {
            
            (identifier, date) in
            
            var nextAlarm: Alarm? = nil
            if let nextAlarmIdentifier = identifier {
                nextAlarm = AlarmDataStore.shared.alarm(withNotificationIdentifier: nextAlarmIdentifier)
            }
            
            DispatchQueue.main.async {
                NotificationCenter.default.post(name: Notification.Name.AlarmSchedulerNextNotificationDateDidChange,
                                                object: nil,
                                                userInfo: [AlarmNotificationUserInfoKey.alarm: nextAlarm as Any,
                                                           AlarmNotificationUserInfoKey.nextTriggerDate: date as Any])
            }
        }
    }
    
    /// - Parameters:
    ///   - identifier: Notification을 Filter할 때 사용 될 Alarm객체 Identifier.
    ///   - completion: 다음에 울릴 Notification의 주인이 되는 Alarm객체의 Identifier와 Notification의 triggerDate가 인자로 절달된다.
    func nextTriggerDate(withAlarmIdentifier identifier: String, completionBlock completion: @escaping (_: String?, _: Date?) -> Void) {
        self.nextTriggerDate(withIdentifier: identifier, completionBlock: completion)
    }
    
    /// - Parameter completion: 다음에 울릴 Notification의 주인이 되는 Alarm객체의 Identifier와 Notification의 triggerDate가 인자로 절달된다.
    func nextTriggerDate(completionHandler completion: @escaping (_: String?, _: Date?) -> Void) {
        self.nextTriggerDate(withIdentifier: nil, completionBlock: completion)
    }
    
    /// UserNotificationCenter에 등록된 Notification들 중에서 다음에 울릴 Notification의 정보를 Completion Block을 통해 전달한다.
    ///
    /// UserNotification에서는 현재 등록된 NotificationRequest를 Completion을 통해 반환하기 때문에 Completion으로 통일 시켜 반환한다
    ///
    /// - Parameters:
    ///   - identifier: Notification을 Filter할 때 사용 될 Alarm객체 Identifier. 만약 nil값이 넘어온다면 모든 Notification들 중에서 가장 가까운 알람을 찾는다.
    ///   - completion: 다음에 울릴 Notification의 주인이 되는 Alarm객체의 Identifier와 Notification의 triggerDate가 인자로 절달된다.
    private func nextTriggerDate(withIdentifier identifier: String?, completionBlock completion: @escaping (_ identifier: String?, _ nextTriggerDate: Date?) -> Void) {
        
        if #available(iOS 10.0, *) {
            
            UNUserNotificationCenter.current().getPendingNotificationRequests {
                
                (requests) in
                
                var filteredRequests = requests
                if let identifier = identifier {
                    filteredRequests = requests.filter { $0.identifier.hasPrefix(identifier) }
                }
                
                let sortedNotifications = filteredRequests.sorted(by: > )
                
                if let calendarNotificationTrigger = sortedNotifications.first?.trigger as? UNCalendarNotificationTrigger {
                    
                    let identifier = sortedNotifications.first?.identifier
                    let nextTriggerDate = calendarNotificationTrigger.nextTriggerDate()
                    
                    completion(identifier, nextTriggerDate)
                    
                } else {
                    completion(nil, nil)
                }
            }
        } else {
            
            guard let notifications = UIApplication.shared.scheduledLocalNotifications else { return completion(nil, nil) }
            
            var filteredNotifications = notifications
            if let identifier = identifier {
                filteredNotifications = notifications.filter { ($0.userInfo?[AlarmNotificationUserInfoKey.identifier] as? String)?.contains(identifier) ?? false }
            }
            let sortedNotifications = filteredNotifications.sorted(by: > )
            
            let identifier = sortedNotifications.first?.userInfo?[AlarmNotificationUserInfoKey.identifier] as? String
            let nextTriggerDate = sortedNotifications.first?.fireDate
            
            completion(identifier, nextTriggerDate)
        }
    }
    
    /// 스누즈 노티피케이션에 사용되는 '@' 구분자를 통해서 남아있는 스누즈 노티피케이션을 찾아 삭제한다.
    ///
    /// - Parameters:
    ///   - alarm: 삭제할 스누즈 노티피케이션과 연관된 알람.
    ///   - completion: 스누즈 노티피케이션을 삭제한 후 불리게 될 CompletionBlock.
    func removeSnoozeNotification(for alarm: Alarm, completionBlock completion: (() -> Void)?) {
        if #available(iOS 10.0, *) {
            
            UNUserNotificationCenter.current().getPendingNotificationRequests {
                
                (pendingNotificationRequests) in
                
                let snoozeIdentifier = "\(alarm.id)@"
                var removeIdnentifiers: [String] = []
                
                for request in pendingNotificationRequests {
                    guard request.identifier.hasPrefix(snoozeIdentifier) else { continue }
                    removeIdnentifiers.append(request.identifier)
                }
                print("Notification \(removeIdnentifiers.count) is removed")
                
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: removeIdnentifiers)
                completion?()
            }
            
        } else {
            // iOS 9.x.
            guard let notifications = UIApplication.shared.scheduledLocalNotifications else { return }
            
            for notification in notifications {
                guard let id = notification.userInfo?["identifier"] as? String else { continue }
                if id.hasPrefix("\(alarm.id)@") {
                    UIApplication.shared.cancelLocalNotification(notification)
                }
            }
        }
    }
    
    
    /// 스누즈 노티피케이션(9분 후에 울리는 노티피케이션)을 노티피케이션 센터에 추가한다.
    ///
    /// 스누즈 노티피케이션은 alarm.id에 '@'를 붙여서 아이디를 설정한다.
    /// 또한 다른 노티피케이션들은 항상 0초를 기준으로 하지만 스누즈 노티피케이션은 초단위를 포함하여 9분후에 울리도록 한다.
    
    /// - Parameter alarm: 스누즈 노티피케이션을 추가할 알람.
    func createSnoozeNotification(for alarm: Alarm) {
        defer {
            self.postNextNotificationDateDidChangeIfNeeded()
        }
        
        if #available(iOS 10.0, *) {
            // Notification Request Identifier.
            let identifier = "\(alarm.id)@"
            
            // Notification Request Content.
            let content = UNMutableNotificationContent()
            content.title = "Dream Recorder"
            content.body = alarm.name
            content.sound = UNNotificationSound(named: "\(alarm.sound)")
            if alarm.isSnooze {
                content.categoryIdentifier = AlarmIdentifier.NotificationCategory.snooze
            } else {
                content.categoryIdentifier = AlarmIdentifier.NotificationCategory.once
            }
            
            // Notification Trigger DateComponents.
            let dateComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: Date().addingSnoozeTimeInterval)
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            
        } else {
            // Fallback on earlier versions
            let snoozeNotification: UILocalNotification = UILocalNotification()
            let snoozeDate = Date().addingSnoozeTimeInterval
            
            snoozeNotification.userInfo = ["identifier": "\(alarm.id)@"]
            snoozeNotification.alertBody = alarm.name
            snoozeNotification.alertAction = "Open App"
            snoozeNotification.soundName = UILocalNotificationDefaultSoundName
            snoozeNotification.fireDate = snoozeDate
            if alarm.isSnooze {
                snoozeNotification.category = AlarmIdentifier.NotificationCategory.snooze
            } else {
                snoozeNotification.category = AlarmIdentifier.NotificationCategory.once
            }
            
            UIApplication.shared.scheduleLocalNotification(snoozeNotification)
        }
    }
    
    /// 앱이 Terminate되는 것을 대비하기 위해서 다음에 울릴 알림을 1분단위로 Notification을 만들어낸다.
    func duplicateNotificationForNextAlarm() {
        if #available(iOS 10.0, *) {
            self.nextTriggerDate {
                
                (notificationIdentifier, nextTriggerDate) in
    
                guard let identifier = notificationIdentifier else { return }
                guard let alarm = AlarmDataStore.shared.alarm(withNotificationIdentifier: identifier) else { return }
                
                // Notification Request Identifier.
                let alarmIdentifier = alarm.id
                
                // Notification Request Content.
                let content = UNMutableNotificationContent()
                content.title = "Dream Recorder"
                content.body = alarm.name
                content.sound = UNNotificationSound(named: "\(alarm.sound)")
                if alarm.isSnooze {
                    content.categoryIdentifier = AlarmIdentifier.NotificationCategory.snooze
                } else {
                    content.categoryIdentifier = AlarmIdentifier.NotificationCategory.once
                }
                
                // Notification Trigger DateComponents.
                var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: alarm.date)
                
                for index in 0...59 {
                    guard let currentHour = dateComponents.hour else { continue }
                    guard let currentMinute = dateComponents.minute else { continue }
                    let nextMiniute = currentMinute + 1
                    dateComponents.minute = nextMiniute < 60 ? nextMiniute : nextMiniute - 60
                    dateComponents.hour = nextMiniute < 60 ? currentHour : currentHour + 1
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                    let request = UNNotificationRequest(identifier: "\(alarmIdentifier)#\(index)", content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }
                print("Notification \(identifier) is created (repeat 60 if terminated)")
            }
        } else {
            // Fallback on earlier versions
            
            self.nextTriggerDate(completionHandler: { (identifier, nextFireDate) in
                
                guard let identifier = identifier else { return }
                guard let nextAlarm = AlarmDataStore.shared.alarm(withNotificationIdentifier: identifier) else { return }
                
                let duplicatingNotification: UILocalNotification = UILocalNotification()
                
                duplicatingNotification.userInfo = ["identifier": "\(nextAlarm.id)#"]
                duplicatingNotification.alertBody = nextAlarm.name
                duplicatingNotification.soundName = UILocalNotificationDefaultSoundName
                if nextAlarm.isSnooze {
                    duplicatingNotification.category = AlarmIdentifier.NotificationCategory.snooze
                } else {
                    duplicatingNotification.category = AlarmIdentifier.NotificationCategory.once
                }
                
                //repeat every minute
                duplicatingNotification.repeatInterval = .minute
                UIApplication.shared.scheduleLocalNotification(duplicatingNotification)
                
            })
        }
    }

    /// 노티피케이션을 추가한다.
    ///
    /// - Parameter alarm: 노티피케이션을 추가할 알람.
    private func addNotification(with alarm: Alarm){
        
        if #available(iOS 10.0, *) {
            
            // Notification Request Identifier.
            let identifier = alarm.id
            
            // Notification Request Content.
            let content = UNMutableNotificationContent()
            content.title = "Dream Recorder"
            content.body = alarm.name
            content.sound = UNNotificationSound.default()
            if alarm.isSnooze {
                content.categoryIdentifier = AlarmIdentifier.NotificationCategory.snooze
            } else {
                content.categoryIdentifier = AlarmIdentifier.NotificationCategory.once
            }
            
            // Notification Trigger DateComponents.
            var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: alarm.date)
            
            switch alarm.weekday {
            case WeekdayOptions.none:   // No Repeat.
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(identifier: "\(identifier)!",
                                                    content: content,
                                                    trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                print("Notification \(identifier) is created no repeat")
                
            case WeekdayOptions.all:    // Repeat Every Weekday.
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "\(identifier)!",
                                                    content: content,
                                                    trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                print("Notification \(identifier) is created (every weekday)")
                
            default:                    // Repeat Each Weekday.
                var triggers: [UNCalendarNotificationTrigger] = []
                
                for weekday in 0 ... 6 {
                    if alarm.weekday.contains(WeekdayOptions(rawValue: 1 << weekday)) {
                        // Discuss
                        dateComponents.weekday = weekday + 1    // Calendar.Component.weekday start index at 1 (1 ~ 7)
                        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                        triggers.append(trigger)
                    }
                }
                
                for (index, trigger) in triggers.enumerated() {
                    let request = UNNotificationRequest(identifier: "\(identifier)!\(index)", content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                    print("Notification \(identifier) is created (\(Calendar.current.weekdaySymbols[trigger.dateComponents.weekday! - 1]))")
                }
            }
        } else {
            // Fallback on earlier versions
            let notification: UILocalNotification = UILocalNotification()
            notification.userInfo = ["identifier": "\(alarm.id)!"]
            notification.alertBody = alarm.name
            notification.alertAction = "Open App"
            notification.soundName = UILocalNotificationDefaultSoundName
            if alarm.isSnooze {
                notification.category = AlarmIdentifier.NotificationCategory.snooze
            } else {
                notification.category = AlarmIdentifier.NotificationCategory.once
            }
            
            let calendarComponents: Set<Calendar.Component> = [.year, .month, .day, .hour, .minute, .weekOfYear]
            var dateComponents = Calendar.current.dateComponents(calendarComponents, from: alarm.date)
            let now = Date()
            var fireDate = Calendar.current.date(from: dateComponents)
            //repeat weekly if repeat weekdays are selected
            switch alarm.weekday {
            case WeekdayOptions.none:   // Once.
                if alarm.date.compare(now) == .orderedAscending {
                    guard let currentDay = dateComponents.day else { return }
                    dateComponents.day = currentDay + 1
                }
                fireDate = Calendar.current.date(from: dateComponents)
                //            notification.fireDate = fireDate
                notification.fireDate = Date().addingTimeInterval(5)
                notification.repeatInterval = .day
                UIApplication.shared.scheduleLocalNotification(notification)
                print("Notification \(alarm.id) is created (Once)")
            case WeekdayOptions.all:    // Repeat Every Weekday.
                notification.repeatInterval = NSCalendar.Unit.day
                notification.fireDate = fireDate
                UIApplication.shared.scheduleLocalNotification(notification)
                print("Notification \(alarm.id) is created (every weekday)")
            default:                    // Repeat Each Weekday.
                for weekday in 0 ... 6 {
                    if alarm.weekday.contains(WeekdayOptions(rawValue: 1 << weekday)) {
                        
                        notification.userInfo = ["identifier": "\(alarm.id)!\(weekday)"]
                        notification.repeatInterval = NSCalendar.Unit.weekOfYear
                        
                        fireDate = Calendar.current.date(from: dateComponents)
                        notification.fireDate = fireDate
                        UIApplication.shared.scheduleLocalNotification(notification)
                        print("Notification \(alarm.id)\(weekday) is created (specific weekday)")
                    }
                }
            }
        }
    }
    
    /// 노티피케이션을 삭제한다.
    ///
    /// - Parameters:
    ///   - alarm: 노티피케이션을 삭제할 알람.
    ///   - completion: 노티피케이션을 삭제한 후 불리는 CompletionBlock.
    private func deleteNotification(with alarm: Alarm, completionBlock completion: (() -> Void)?) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
                var removeIdnentifiers: [String] = []
                for request in requests {
                    if request.identifier.hasPrefix(alarm.id) {
                        removeIdnentifiers.append(request.identifier)
                    }
                }
                print("Notification \(removeIdnentifiers.count) is removed")
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: removeIdnentifiers)
                completion?()
            }
            
        } else {
            // Fallback on earlier versions
            guard let notifications = UIApplication.shared.scheduledLocalNotifications else { return }
            
            for notification in notifications {
                
                guard let id = notification.userInfo?["identifier"] as? String else { continue }
                guard id.hasPrefix(alarm.id) else { continue }
                
                UIApplication.shared.cancelLocalNotification(notification)
            }
            completion?()
        }
    }

    /// 노티피케이션을 업데이트한다.
    ///
    /// 노티피케이션 업데이트는 해당 노티피케이션을 전부 삭제하고 다시 추가한다.
    ///
    /// - Parameter alarm: Notification을 업데이트할 알람
    private func updateNotification(with alarm: Alarm) {
        self.deleteNotification(with: alarm) { 
            self.addNotification(with: alarm)
            self.postNextNotificationDateDidChangeIfNeeded()
        }
    }

    /// iOS10.x: UserNotification을 요청하고 Snooze와 Stop액션을 각각의 카테고리에 설정한 후 UserNotificationCenter에 등록한다.
    /// iOS9.x: UIUserNotification에서 Snooze와 Stop액션을 각각의 카테고리에 설정한 후 UserNotificationCenter에 등록한다.
    private func setupNotificationSetting(){
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                if granted {
                    let snoozeAction = UNNotificationAction(identifier: AlarmIdentifier.NotificationAction.snooze,
                                                            title: "Snooze".localized,
                                                            options: .foreground)
                    let stopAction = UNNotificationAction(identifier: AlarmIdentifier.NotificationAction.stop,
                                                          title: "Stop".localized,
                                                          options: .destructive)
                    
                    let snoozeCategory = UNNotificationCategory(identifier: AlarmIdentifier.NotificationCategory.snooze,
                                                                actions: [snoozeAction, stopAction],
                                                                intentIdentifiers: [],
                                                                options: [])
                    let onceCategory = UNNotificationCategory(identifier: AlarmIdentifier.NotificationCategory.once,
                                                              actions: [stopAction],
                                                              intentIdentifiers: [],
                                                              options: [])
                    
                    UNUserNotificationCenter.current().setNotificationCategories([snoozeCategory, onceCategory])
                }
            }
        }else {
            // Notification Types.
            let notificationTypes: UIUserNotificationType = [.alert, .sound]
            
            // Notification Actions.
            let stopAction = UIMutableUserNotificationAction()
            stopAction.identifier = AlarmIdentifier.NotificationAction.stop
            stopAction.title = "Stop".localized
            stopAction.activationMode = UIUserNotificationActivationMode.background
            stopAction.isDestructive = true
            stopAction.isAuthenticationRequired = false
            
            let snoozeAction = UIMutableUserNotificationAction()
            snoozeAction.identifier = AlarmIdentifier.NotificationAction.snooze
            snoozeAction.title = "Snooze".localized
            snoozeAction.activationMode = UIUserNotificationActivationMode.background
            snoozeAction.isDestructive = false
            snoozeAction.isAuthenticationRequired = false
            
            let snoozeActions = [snoozeAction, stopAction]
            let snoozeActionsMinimal = [snoozeAction, stopAction]
            
            let onceActions = [stopAction]
            let onceActionsMinimal = [stopAction]
            
            // Notification Category.
            let snoozeCategory = UIMutableUserNotificationCategory()
            snoozeCategory.identifier = AlarmIdentifier.NotificationCategory.snooze
            snoozeCategory.setActions(snoozeActions, for: .default)
            snoozeCategory.setActions(snoozeActionsMinimal, for: .minimal)
            
            let onceCategory = UIMutableUserNotificationCategory()
            onceCategory.identifier = AlarmIdentifier.NotificationCategory.once
            onceCategory.setActions(onceActions, for: .default)
            onceCategory.setActions(onceActionsMinimal, for: .minimal)
            
            // Notification Settings.
            let categoriesForSettings = Set(arrayLiteral: snoozeCategory, onceCategory)
            let notificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: categoriesForSettings)
            UIApplication.shared.registerUserNotificationSettings(notificationSettings)

        }
    }
    
    func createAlertNotificationForAppWillTerminate() {
        
        if #available(iOS 10.0, *) {
            
            // Notification Request Identifier.
            let identifier = "AlertAppWillTerminateNotification"
            
            // Notification Request Content.
            let content = UNMutableNotificationContent()
            content.title = "Dream Recorder will terminate and chagen alarm sound."
            content.body = "now Dream Recorder can`t play your song."
            content.sound = UNNotificationSound.default()
            
            // Notification Trigger DateComponents.
            let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 3, repeats: false)
            let request = UNNotificationRequest(identifier: "\(identifier)!",
                                                content: content,
                                                trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)

        } else {
            // Fallback on earlier versions
            let notification: UILocalNotification = UILocalNotification()
            notification.userInfo = ["identifier": "AlertAppWillTerminateNotification"]
            notification.alertBody = "Dream Recorder will terminate and chagen alarm sound."
            notification.soundName = UILocalNotificationDefaultSoundName
            
            notification.fireDate = Date().addingTimeInterval(5)
            UIApplication.shared.scheduleLocalNotification(notification)
        }
    }
}

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

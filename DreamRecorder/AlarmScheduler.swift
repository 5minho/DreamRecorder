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

extension Notification.Name {
    // AlarmScheduler -> AlarmDataStore.
    // @abstract        Post if there is notification which have been delivered.
    // @discussion      The userInfo dictionary contains an alarm object that is changed.
    //                  Use AlarmNotificationUserInfoKey to access this value.
    static let AlarmSchedulerNotificationDidDelivered = Notification.Name("AlarmSchedulerNotificationDidDelivered")
    // AlarmScheduler -> SoundManager.
    static let AlarmSchedulerNextNotificationDateDidChange = Notification.Name("AlarmSchedulerNextNotificationDateDidChange")
    
//    // UIAppDelegate -> AlarmScheduler.
//    static let ApplicationDidReceiveResponse = Notification.Name("ApplicationDidReceiveResponse")
//    static let ApplicationWillPresentNotification = Notification.Name("ApplicationWillPresentNotification")
}

class AlarmScheduler {
    
    // MARK: Properties.
    // Singleton.
    static let shared: AlarmScheduler = AlarmScheduler()
    
    private struct CategoryIdentifier {
        static let snoozeLocalNotificationCategory = "SnoozeLocalNotificationCategory"
        static let onceLocalNotificationCategory = "OnceLocalNotificationCategory"
    }
    private struct ActionIdentifier {
        static let snoozeAction = "SnoozeAction"
        static let stopAction = "StopAction"
    }
    
    func awake(){
        
    }
    
    // MARK: Initializer.
    init() {
        self.setupNotificationSetting()
        self.updateNotificationsIfNeeded()
        self.postNextNotificationDateDidChangeIfNeeded()
        
        // AlarmDataStore -> AlarmScheduler.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleAlarmDataStoreDidAddAlarm(sender:)),
                                               name: Notification.Name.AlarmDataStoreDidAddAlarm,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleAlarmDataStoreDidUpdateAlarm(sender:)),
                                               name: Notification.Name.AlarmDataStoreDidUpdateAlarm,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleAlarmDataStoreDidDeleteAlarm(sender:)),
                                               name: Notification.Name.AlarmDataStoreDidDeleteAlarm,
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
            self.postNextNotificationDateDidChangeIfNeeded()
        }
    }
    
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
    
    func updateNotificationsIfNeeded() {
        if #available(iOS 10.0, *) {
            // 앱이 꺼질 것을 대배하여 여려개 생성해놓은 아직 남아있는 Notification들을 삭제한다.
            // 앱이 Terminate되어서 uplicate되었는데 몇 번째의 Notification을 받은 상태로 앱을 실행했는지 알 수 없으므로.
            UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: { (notifications) in
                var duplicatedRequests: [String] = []
                for deliveredNotificaton in notifications {
                    if deliveredNotificaton.request.identifier.contains("#") {
                        duplicatedRequests.append(deliveredNotificaton.request.identifier)
                    }
                }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: duplicatedRequests)
            })
            
            
            // Alarm 목록중에 Notifiation을 가지고 있지 않은 Alarm은 Inactivate해주어야 한다.
            // 사용자가 반복이 없는 알람을 설정해 놓았을 경우 해당 알람 시간이 지난 후 라면 비활성화 하여야한다.
            // 앱 실행단계(Scheduler Initializer), background에서 foreground진입단계, present단계, didreceive단계에서 호출한다. 
            // TODO: DidReceive는 foreground가 대체하므로 필요 없을 것.
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                
                var snoozeRequests: [String] = []
                
                for request in requests {
                    guard request.identifier.hasSuffix("@") else { continue }
                    snoozeRequests.append(request.identifier)
                }
                
                if snoozeRequests.isEmpty == false {
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: snoozeRequests)
                }
                
                // 알람 객체는 있으나 Notification이 없는 객체는 alarm.isActive를 false로 바꾸어 주어야함.
                let inActiveAlarms = AlarmDataStore.shared.alarms.filter({ (alarm) -> Bool in
                    
                    var notificationNotExist = true
                    
                    for request in requests {
                        guard request.identifier.hasPrefix(alarm.id) else { continue }
                        notificationNotExist = false
                        break
                    }
                    
                    return notificationNotExist
                })

                guard inActiveAlarms.isEmpty == false else { return }
                
                NotificationCenter.default.post(name: Notification.Name.AlarmSchedulerNotificationDidDelivered,
                                                object: nil,
                                                userInfo: [AlarmNotificationUserInfoKey.alarms: inActiveAlarms])
            })
        } else {
            guard let notifications = UIApplication.shared.scheduledLocalNotifications else { return }
            
            // 중복알람을 위한 노티피케이션을 삭제한다.
            // 스누즈 노트피케이션을 삭제한다.
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
    
    // MARK: Methods.
    // @abstract        Post if the nearst notification did change.
    private func postNextNotificationDateDidChangeIfNeeded(){
        self.nextTriggerDate(completionHandler: { (identifier, date) in
            var nextAlarm: Alarm? = nil
            if let nextAlarmIdentifier = identifier {
                nextAlarm = AlarmDataStore.shared.alarm(withNotificationIdentifier: nextAlarmIdentifier)
            }
            
            NotificationCenter.default.post(name: Notification.Name.AlarmSchedulerNextNotificationDateDidChange,
                                            object: nil,
                                            userInfo: [AlarmNotificationUserInfoKey.alarm: nextAlarm as Any,
                                                       AlarmNotificationUserInfoKey.nextTriggerDate: date as Any])
        })
    }
    
    /// UserNotificationCenter에 등록된 Notification들 중에서 해당 Identifier를 가진 노티피케이션의 다음에 발생할 날짜를 completion을 통해 반환합니다.
    /// UserNotification에서는 현재 등록된 NotificationRequest를 Completion을 통해 반환하기 때문에 Completion으로 통일 시켜 반환한다.
    ///
    /// - Parameters:
    ///   - identifier: Notification을 Filter할 때 사용 될 Alarm객체 Identifier.
    ///   - completion:
    func nextTriggerDate(withAlarmIdentifier identifier: String, completionBlock completion: @escaping (_: String?, _: Date?) -> Void) {
        self.nextTriggerDate(withIdentifier: identifier, completionBlock: completion)
    }
    
    func nextTriggerDate(completionHandler completion: @escaping (_: String?, _: Date?) -> Void) {
        self.nextTriggerDate(withIdentifier: nil, completionBlock: completion)
    }
    
    
    private func nextTriggerDate(withIdentifier identifier: String?, completionBlock completion: @escaping (_ identifier: String?, _ nextTriggerDate: Date?) -> Void) {
        
        if #available(iOS 10.0, *) {
            
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                var filteredRequests = requests
                if let identifier = identifier {
                    filteredRequests = requests.filter { $0.identifier.hasPrefix(identifier) }
                }
                let ascendingNotifications = filteredRequests.sorted(by: > )
                if let calendarNotificationTrigger = ascendingNotifications.first?.trigger as? UNCalendarNotificationTrigger {
                    let identifier = ascendingNotifications.first?.identifier
                    let nextTriggerDate = calendarNotificationTrigger.nextTriggerDate()
                    completion(identifier, nextTriggerDate)
                } else {
                    completion(nil, nil)
                }
            })
        } else {
            
            guard let notifications = UIApplication.shared.scheduledLocalNotifications else { return completion(nil, nil) }
            
            var filteredNotifications = notifications
            if let identifier = identifier {
                filteredNotifications = notifications.filter { ($0.userInfo?[AlarmNotificationUserInfoKey.identifier] as? String)?.contains(identifier) ?? false }
            }
            let ascendingNotifications = filteredNotifications.sorted(by: > )
            let identifier = ascendingNotifications.first?.userInfo?[AlarmNotificationUserInfoKey.identifier] as? String
            let nextTriggerDate = ascendingNotifications.first?.fireDate
            completion(identifier, nextTriggerDate)
        }
    }
    
    func removeSnoozeNotification(for alarm: Alarm, completionBlock completion: (() -> Void)?) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
                let snoozeIdentifier = "\(alarm.id)@"
                var removeIdnentifiers: [String] = []
                for request in requests {
                    if request.identifier.hasPrefix(snoozeIdentifier) {
                        removeIdnentifiers.append(request.identifier)
                    }
                }
                print("Notification \(removeIdnentifiers.count) is removed")
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: removeIdnentifiers)
                completion?()
            }
            
        } else {
//            // Fallback on earlier versions
//            self.removeNotificationFallback(with: alarm)
//            completion?()
        }
    }
    
    func duplicateSnoozeNotification(for alarm: Alarm) {
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
            content.categoryIdentifier = alarm.isSnooze ? CategoryIdentifier.snoozeLocalNotificationCategory : CategoryIdentifier.onceLocalNotificationCategory
            content.sound = UNNotificationSound(named: "\(alarm.sound)")
            
            // Notification Trigger DateComponents.
            let dateComponents = Calendar.current.dateComponents([.hour, .minute, .second], from: Date().addingTimeInterval(60))
            
            let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
            let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
            UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
            
            print("Notification \(identifier) is created (for Snooze)")
        } else {
            // Fallback on earlier versions
            let snoozeNotification: UILocalNotification = UILocalNotification()
            let snoozeDate = Date().addingTimeInterval(60*9)
            
            snoozeNotification.userInfo = ["identifier": "\(alarm.id)@"]
            snoozeNotification.alertBody = alarm.name
            snoozeNotification.alertAction = "Open App"
            snoozeNotification.category = alarm.isSnooze ? CategoryIdentifier.snoozeLocalNotificationCategory : CategoryIdentifier.onceLocalNotificationCategory
            snoozeNotification.soundName = UILocalNotificationDefaultSoundName
            snoozeNotification.fireDate = snoozeDate
            
            UIApplication.shared.scheduleLocalNotification(snoozeNotification)
            print("Notification \(alarm.id) is created (for Snooze)")
        }
    }
    
    func duplicateNotificationByFollowingAlarm() {
        if #available(iOS 10.0, *) {
            self.nextNotificationRequest { (request) in
                
                guard let notificationRequest = request else { return }
                guard let alarm = AlarmDataStore.shared.alarm(withNotificationIdentifier: notificationRequest.identifier) else { return }
                
                // Notification Request Identifier.
                let identifier = alarm.id
                
                // Notification Request Content.
                let content = UNMutableNotificationContent()
                content.title = "Dream Recorder"
                content.body = alarm.name
                content.categoryIdentifier = alarm.isSnooze ? CategoryIdentifier.snoozeLocalNotificationCategory : CategoryIdentifier.onceLocalNotificationCategory
                content.sound = UNNotificationSound(named: "\(alarm.sound)")
//                content.sound = UNNotificationSound.default()
                
                
                // Notification Trigger DateComponents.
                var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: alarm.date)
                
                for index in 0...59 {
                    guard let currentHour = dateComponents.hour else { continue }
                    guard let currentMinute = dateComponents.minute else { continue }
                    let nextMiniute = currentMinute + 1
                    dateComponents.minute = nextMiniute < 60 ? nextMiniute : nextMiniute - 60
                    dateComponents.hour = nextMiniute < 60 ? currentHour : currentHour + 1
                    let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                    let request = UNNotificationRequest(identifier: "\(identifier)#\(index)", content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }
                print("Notification \(identifier) is created (repeat 60 if terminated)")
            }
        } else {
            // Fallback on earlier versions
            
            guard let notification = self.nextLocalNotification() else { return }
            guard let fireDate = notification.fireDate else { return }
            guard let identifier = notification.userInfo?["identifier"] as? String else { return }
            guard let alarm = AlarmDataStore.shared.alarm(withNotificationIdentifier: identifier) else { return }
            
            let duplicatingNotification: UILocalNotification = UILocalNotification()
            
            notification.userInfo = ["identifier": "\(alarm.id)#Duplicated"]
            notification.alertBody = alarm.name
            notification.alertAction = "Open App"
            notification.category = alarm.isSnooze ? CategoryIdentifier.snoozeLocalNotificationCategory : CategoryIdentifier.onceLocalNotificationCategory
            notification.soundName = UILocalNotificationDefaultSoundName
            
            //repeat every minute
            notification.repeatInterval = .minute
            UIApplication.shared.scheduleLocalNotification(notification)
        }
    }
    
    @available(iOS 10.0, *)
    func nextNotificationRequest(completionHandler completion: @escaping (UNNotificationRequest?) -> Void) {
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                let ascendingNotifications = requests.sorted(by: > )
                completion(ascendingNotifications.first)
                
            })
    }
    
    func nextLocalNotification() -> UILocalNotification? {
        guard let notifications = UIApplication.shared.scheduledLocalNotifications else { return nil }
        let ascendingNotifications = notifications.sorted(by: > )
        return ascendingNotifications.first
    }
    
    // MARK: For iOS 10.x
    func removeAllNotifications() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        } else {
            // Fallback on earlier versions
        }
    }
    
    @available(iOS 10.0, *)
    func getDeliveredNotifications(completionHandler: @escaping ([UNNotification]) -> Swift.Void){
//        UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: completionHandler)
        UNUserNotificationCenter.current().getDeliveredNotifications { (notifications) in
            completionHandler(notifications)
            UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        }
    }
    
    @available(iOS 10.0, *)
    func getPendingNotificationRequests(completion: @escaping (_ requests: [UNNotificationRequest]) -> Void) {
        UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
            completion(requests)
        }
    }
    
    func getScheduledLocalNotifications() -> [UILocalNotification]? {
        return UIApplication.shared.scheduledLocalNotifications
    }

    // MARK: CRUD for Notification.
    // Control UserNotificaton for iOS 10.x
    private func addNotification(with alarm: Alarm){
        
        if #available(iOS 10.0, *) {
            
            // Notification Request Identifier.
            let identifier = alarm.id
            
            // Notification Request Content.
            let content = UNMutableNotificationContent()
            content.title = "Dream Recorder"
            content.body = alarm.name
            content.categoryIdentifier = alarm.isSnooze ? CategoryIdentifier.snoozeLocalNotificationCategory : CategoryIdentifier.onceLocalNotificationCategory
            content.sound = UNNotificationSound.default()
            
            // Notification Trigger DateComponents.
            var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: alarm.date)
            
            switch alarm.weekday {
            case WeekdayOptions.none:   // No Repeat.
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(identifier: "\(identifier)!", content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                print("Notification \(identifier) is created no repeat")
                
            case WeekdayOptions.all:    // Repeat Every Weekday.
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: "\(identifier)!", content: content, trigger: trigger)
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
            self.addNotificationFallback(with: alarm)
        }
    }
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
            self.removeNotificationFallback(with: alarm)
            completion?()
        }
    }
    private func updateNotification(with alarm: Alarm) {
        self.deleteNotification(with: alarm) { 
            self.addNotification(with: alarm)
            self.postNextNotificationDateDidChangeIfNeeded()
        }
    }
    
    
    
    private func setupNotificationSetting(){
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                if granted {
                    let snoozeAction = UNNotificationAction(identifier: ActionIdentifier.snoozeAction,
                                                            title: "Snooze",
                                                            options: .foreground)
                    let stopAction = UNNotificationAction(identifier: ActionIdentifier.stopAction,
                                                          title: "Stop",
                                                          options: .destructive)
                    
                    let snoozeCategory = UNNotificationCategory(identifier: CategoryIdentifier.snoozeLocalNotificationCategory,
                                                                actions: [snoozeAction, stopAction],
                                                                intentIdentifiers: [],
                                                                options: [])
                    let onceCategory = UNNotificationCategory(identifier: CategoryIdentifier.onceLocalNotificationCategory,
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
            stopAction.identifier = "StopAction"
            stopAction.title = "Stop"
            stopAction.activationMode = UIUserNotificationActivationMode.background
            stopAction.isDestructive = true
            stopAction.isAuthenticationRequired = false
            
            let snoozeAction = UIMutableUserNotificationAction()
            snoozeAction.identifier = "SnoozeAction"
            snoozeAction.title = "Snooze"
            snoozeAction.activationMode = UIUserNotificationActivationMode.background
            snoozeAction.isDestructive = false
            snoozeAction.isAuthenticationRequired = false
            
            let snoozeActions = [snoozeAction, stopAction]
            let snoozeActionsMinimal = [snoozeAction, stopAction]
            
            let onceActions = [stopAction]
            let onceActionsMinimal = [stopAction]
            
            // Notification Category.
            let snoozeCategory = UIMutableUserNotificationCategory()
            snoozeCategory.identifier = CategoryIdentifier.snoozeLocalNotificationCategory
            snoozeCategory.setActions(snoozeActions, for: .default)
            snoozeCategory.setActions(snoozeActionsMinimal, for: .minimal)
            
            let onceCategory = UIMutableUserNotificationCategory()
            onceCategory.identifier = CategoryIdentifier.onceLocalNotificationCategory
            onceCategory.setActions(onceActions, for: .default)
            onceCategory.setActions(onceActionsMinimal, for: .minimal)
            
            // Notification Settings.
            let categoriesForSettings = Set(arrayLiteral: snoozeCategory, onceCategory)
            let notificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: categoriesForSettings)
            UIApplication.shared.registerUserNotificationSettings(notificationSettings)

        }
    }
    private func addNotificationFallback(with alarm: Alarm) {
        let notification: UILocalNotification = UILocalNotification()
        notification.userInfo = ["identifier": "\(alarm.id)!"]
        notification.alertBody = alarm.name
        notification.alertAction = "Open App"
        notification.category = alarm.isSnooze ? CategoryIdentifier.snoozeLocalNotificationCategory : CategoryIdentifier.onceLocalNotificationCategory
        notification.soundName = UILocalNotificationDefaultSoundName
        
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
    private func removeNotificationFallback(with alarm: Alarm) {
        guard let notifications = UIApplication.shared.scheduledLocalNotifications else { return }
        for notification in notifications {
            guard let id = notification.userInfo?["identifier"] as? String else { continue }
            if id.hasPrefix(alarm.id) {
                UIApplication.shared.cancelLocalNotification(notification)
            }
        }
    }
}

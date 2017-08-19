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

extension Notification.Name {
    // Posted if notification is delivered whatever app state or user response to notification.
    static let AlarmSchedulerNotificationDidDelivered = Notification.Name("AlarmSchedulerNotificationDidDelivered")
    static let AlarmSchedulerNextNotificationDateDidChange = Notification.Name("AlarmSchedulerNextNotificationDateDidChange")
    
    // UIAppDelegate
    static let ApplicationDidReceiveResponse = Notification.Name("ApplicationDidReceiveResponse")
    static let ApplicationWillPresentNotification = Notification.Name("ApplicationWillPresentNotification")
}

class AlarmScheduler {
    
    static let shared: AlarmScheduler = AlarmScheduler()
    
    private struct Identifier {
        static let snoozeLocalNotificationCategory = "SnoozeLocalNotificationCategory"
        static let onceLocalNotificationCategory = "OnceLocalNotificationCategory"
    }
    
    func awake(){
        self.handleUIApplicationWillEnterForeground(sender: Notification(name: Notification.Name.UIApplicationWillEnterForeground))
    }
    
    init() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                if granted {
                    let snoozeAction = UNNotificationAction(identifier: "SnoozeAction",
                                                            title: "Snooze",
                                                            options: .foreground)
                    let stopAction = UNNotificationAction(identifier: "StopAction",
                                                          title: "Stop",
                                                          options: .destructive)
                    
                    let snoozeCategory = UNNotificationCategory(identifier: Identifier.snoozeLocalNotificationCategory,
                                                                actions: [snoozeAction, stopAction],
                                                                intentIdentifiers: [],
                                                                options: [])
                    let onceCategory = UNNotificationCategory(identifier: Identifier.onceLocalNotificationCategory,
                                                              actions: [stopAction],
                                                              intentIdentifiers: [],
                                                              options: [])
                    
                    UNUserNotificationCenter.current().setNotificationCategories([snoozeCategory, onceCategory])
                }
            }
        } else {
            // Fallback on earlier versions
            self.setupNotification()
        }
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
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleSoundManagerDidPlayAlarmToEnd),
                                               name: Notification.Name.SoundManagerDidPlayAlarmToEnd,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleUIApplicationWillEnterForeground(sender:)),
                                               name: Notification.Name.UIApplicationWillEnterForeground,
                                               object: nil)
    }
    
    @objc func handleUIApplicationWillEnterForeground(sender: Notification){
        print("AlarmScheduler - Handle Enter Foreground")
        if #available(iOS 10.0, *) {
            // Remove All Duplicated Notification.
            UNUserNotificationCenter.current().getDeliveredNotifications(completionHandler: { (notifications) in
                var duplicatedRequests: [String] = []
                for deliveredNotificaton in notifications {
                    if deliveredNotificaton.request.identifier.contains("#") {
                        duplicatedRequests.append(deliveredNotificaton.request.identifier)
                    }
                }
                UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: duplicatedRequests)
            })
            
            // update Alarm`s isActive if repeat of that is false
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                let inActiveAlarms = AlarmDataStore.shared.alarms.filter({ (alarm) -> Bool in
                    var notificationNotExist = true
                    
                    for request in requests {
                        let identifier = "\(request.identifier)"
                        if identifier.hasPrefix(alarm.id) {
                            notificationNotExist = false
                            break
                        }
                    }
                    return notificationNotExist
                })

                if inActiveAlarms.count > 0 {
                    NotificationCenter.default.post(name: Notification.Name.AlarmSchedulerNotificationDidDelivered,
                                                    object: nil,
                                                    userInfo: ["alarms": inActiveAlarms])
                }
                
            })
        } else {
            guard let notifications = UIApplication.shared.scheduledLocalNotifications else { return }
            
            // Remove All Duplicated Notification.
            for notification in notifications {
                guard let notificationIdentifier = notification.userInfo?["identifier"] as? String else { continue }
                if notificationIdentifier.contains("#") {
                    UIApplication.shared.cancelLocalNotification(notification)
                }
            }
            
            let inActiveAlarms = AlarmDataStore.shared.alarms.filter({ (alarm) -> Bool in
                var isDelivered = true
                for notification in notifications {
                    guard let identifier = notification.userInfo?["identifier"] as? String else { continue }
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
                                                userInfo: ["alarms": inActiveAlarms])
            }
        }
    }
    
    @objc func handleSoundManagerDidPlayAlarmToEnd() {
        if #available(iOS 10.0, *) {
            self.nextNotificationRequest { (request) in
                guard let requestIdentifier = request?.identifier else { return }
                guard let alarm = AlarmDataStore.shared.alarm(withNotificationIdentifier: requestIdentifier) else { return }
                self.postNextNotificationDateDidChangeIfNeeded(with: alarm)
            }
        } else {
            let notification = self.nextLocalNotification()
            guard let notificationIdentifier = notification?.userInfo?["identifier"] as? String else { return }
            guard let alarm = AlarmDataStore.shared.alarm(withNotificationIdentifier: notificationIdentifier) else { return }
            self.postNextNotificationDateDidChangeIfNeeded(with: alarm)
        }
    }
    
    @objc private func handleAlarmDataStoreDidAddAlarm(sender: Notification) {
        guard let alarm = sender.userInfo?["alarm"] as? Alarm else { return }
        self.addNotification(with: alarm)
        self.postNextNotificationDateDidChangeIfNeeded(with: alarm)
    }
    @objc private func handleAlarmDataStoreDidUpdateAlarm(sender: Notification) {
        guard let alarm = sender.userInfo?["alarm"] as? Alarm else { return }
        if alarm.isActive {
            self.updateNotification(with: alarm)
        } else {
            self.deleteNotification(with: alarm)
        }
        self.postNextNotificationDateDidChangeIfNeeded(with: alarm)
    }
    @objc private func handleAlarmDataStoreDidDeleteAlarm(sender: Notification) {
        guard let alarm = sender.userInfo?["alarm"] as? Alarm else { return }
        self.deleteNotification(with: alarm)
        self.postNextNotificationDateDidChangeIfNeeded(with: alarm)
    }
    
    func postNextNotificationDateDidChangeIfNeeded(with alarm: Alarm){
        self.nextTriggerDate(completionHandler: { (date) in
            NotificationCenter.default.post(name: Notification.Name.AlarmSchedulerNextNotificationDateDidChange,
                                            object: nil,
                                            userInfo: ["alarm": alarm,
                                                       "nextDate": date as Any])
        })
    }
    
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
                content.categoryIdentifier = alarm.isSnooze ? Identifier.snoozeLocalNotificationCategory : Identifier.onceLocalNotificationCategory
                content.sound = UNNotificationSound(named: "\(alarm.sound).wav")
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
            notification.category = alarm.isSnooze ? Identifier.snoozeLocalNotificationCategory : Identifier.onceLocalNotificationCategory
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
    
    func notificationDidChange(){
        
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
            content.categoryIdentifier = alarm.isSnooze ? Identifier.snoozeLocalNotificationCategory : Identifier.onceLocalNotificationCategory
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
    private func deleteNotification(with alarm: Alarm) {
        
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
            }
            
        } else {
            // Fallback on earlier versions
            self.removeNotificationFallback(with: alarm)
        }
    }
    private func updateNotification(with alarm: Alarm) {
        self.deleteNotification(with: alarm)
        self.addNotification(with: alarm)
    }
    
    
    // Control LocalNotification for iOS 9.x
    private func setupNotification(){
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
        snoozeCategory.identifier = Identifier.snoozeLocalNotificationCategory
        snoozeCategory.setActions(snoozeActions, for: .default)
        snoozeCategory.setActions(snoozeActionsMinimal, for: .minimal)
        
        let onceCategory = UIMutableUserNotificationCategory()
        onceCategory.identifier = Identifier.onceLocalNotificationCategory
        onceCategory.setActions(onceActions, for: .default)
        onceCategory.setActions(onceActionsMinimal, for: .minimal)
        
        // Notification Settings.
        let categoriesForSettings = Set(arrayLiteral: snoozeCategory, onceCategory)
        let notificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: categoriesForSettings)
        UIApplication.shared.registerUserNotificationSettings(notificationSettings)
    }
    private func addNotificationFallback(with alarm: Alarm) {
        let notification: UILocalNotification = UILocalNotification()
        notification.userInfo = ["identifier": "\(alarm.id)!"]
        notification.alertBody = alarm.name
        notification.alertAction = "Open App"
        notification.category = alarm.isSnooze ? Identifier.snoozeLocalNotificationCategory : Identifier.onceLocalNotificationCategory
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

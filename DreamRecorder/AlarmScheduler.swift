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

class AlarmScheduler {
    
    private struct Identifier {
        static let snoozeLocalNotificationCategory = "SnoozeLocalNotificationCategory"
        static let onceLocalNotificationCategory = "onceLocalNotificationCategory"
    }
    
    init() {
        print("initiallize Scheduler")
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                if granted {
                    let snoozeAction = UNNotificationAction(identifier: "SnoozeAction",
                                                            title: "Snooze",
                                                            options: .foreground)
                    let stopAction = UNNotificationAction(identifier: "StopAction",
                                                          title: "stop",
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
    }
    
    // MARK: For iOS 10.x
    func removeAllNotifications() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
        } else {
            // Fallback on earlier versions
        }
    }
    
    func getNotifications() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
                for request in requests {
                    print("\(request.identifier) \(request.trigger.debugDescription)")
                }
            }
        } else {
            // Fallback on earlier versions
        }
    }
    
    func deleteNotification(with alarm: Alarm) {
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getPendingNotificationRequests { (requests) in
                var removeIdnentifiers: [String] = []
                for request in requests {
                    if request.identifier.contains(alarm.id) {
                        removeIdnentifiers.append(request.identifier)
                    }
                    UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: removeIdnentifiers)
                }
                print("Notification \(removeIdnentifiers.count) is removed")
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.id])
        } else {
            // Fallback on earlier versions
            self.removeNotificationFallback(with: alarm)
        }
    }
    
    func updateNotification(with alarm: Alarm) {
        self.deleteNotification(with: alarm)
        self.addNotification(with: alarm)
    }
    
    func addNotification(with alarm: Alarm){

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
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                print("Notification \(identifier) is created no repeat")
                
            case WeekdayOptions.all:    // Repeat Every Weekday.
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
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
                    let request = UNNotificationRequest(identifier: "\(identifier)\(index)", content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                    print("Notification \(identifier) is created (\(Calendar.current.weekdaySymbols[trigger.dateComponents.weekday! - 1]))")
                }
            }
        } else {
            // Fallback on earlier versions
            self.addNotificationFallback(with: alarm)
        }
    }
    
    // MARK: For iOS 9.x
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
    
    // MARK: fallback function.
    private func removeNotificationFallback(with alarm: Alarm) {
        guard let notifications = UIApplication.shared.scheduledLocalNotifications else { return }
        for notification in notifications {
            guard let id = notification.userInfo?["identifier"] as? String else { continue }
            if id.hasPrefix(alarm.id) {
                UIApplication.shared.cancelLocalNotification(notification)
            }
        }
    }
    
    private func addNotificationFallback(with alarm: Alarm) {
        let notification: UILocalNotification = UILocalNotification()
        notification.userInfo = ["identifier": "\(alarm.id)"]
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
                    
                    notification.userInfo = ["identifier": "\(alarm.id)\(weekday)"]
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

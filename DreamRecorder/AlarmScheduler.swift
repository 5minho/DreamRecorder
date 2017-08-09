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

extension NSObject {
    static func classNameToString() -> String {
        return String(reflecting: type(of: self)).components(separatedBy: ".").last!
    }
    func classNameToString() -> String {
        return String(reflecting: type(of: self)).components(separatedBy: ".").last!
    }
}

class AlarmScheduler {
    
    private struct Identifier {
        static let localNotificationCategory = "AlarmLocalNotificationCategory"
    }
    
    init() {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound]) { (granted, error) in
                if granted {
                    
                }
            }
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
                    print("Notification \(removeIdnentifiers.count) is removed")
                }
            }
            UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [alarm.id])
        } else {
            // Fallback on earlier versions
            self.removeNotificationFallback(with: alarm)
        }
    }
    
    func addNotification(with alarm: Alarm){

        if #available(iOS 10.0, *) {
            
            // Notification Request Identifier.
            let identifier = alarm.id
            
            // Notification Request Content.
            let content = UNMutableNotificationContent()
            content.title = "Dream Recorder"
            content.body = alarm.name
            content.sound = UNNotificationSound.default()

            // Notification Trigger DateComponents.
            var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: alarm.date)
            
            switch alarm.weekday {
            case WeekdayOptions.none:   // No Repeat.
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: false)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                
            case WeekdayOptions.all:    // Repeat Every Weekday.
                let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)
                UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)

            default:                    // Repeat Each Weekday.
                var triggers: [UNCalendarNotificationTrigger] = []
                
                for weekday in 0 ... 6 {
                    if alarm.weekday.contains(WeekdayOptions(rawValue: 1 << weekday)) {
                        dateComponents.weekday = weekday
                        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
                        triggers.append(trigger)
                    }
                }
                
                for (index, trigger) in triggers.enumerated() {
                    let request = UNNotificationRequest(identifier: "\(identifier)\(index)", content: content, trigger: trigger)
                    UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
                }
            }
        } else {
            // Fallback on earlier versions
            self.addNotificationFallback(with: alarm)
        }
    }
    
    private func setupNotification(alarm: Alarm){
        // Notification Types.
        let notificationTypes: UIUserNotificationType = [.alert, .sound]
        
        // Notification Actions.
        let stopAction = UIMutableUserNotificationAction()
        stopAction.identifier = "StopAction"
        stopAction.title = "OK"
        stopAction.activationMode = UIUserNotificationActivationMode.background
        stopAction.isDestructive = false
        stopAction.isAuthenticationRequired = false
        
        let snoozeAction = UIMutableUserNotificationAction()
        snoozeAction.identifier = "SnoozeAction"
        snoozeAction.title = "Snooze"
        snoozeAction.activationMode = UIUserNotificationActivationMode.background
        snoozeAction.isDestructive = false
        snoozeAction.isAuthenticationRequired = false
        
        let actionsArray = alarm.isSnooze ? [UIUserNotificationAction](arrayLiteral: snoozeAction, stopAction) : [UIUserNotificationAction](arrayLiteral: stopAction)
        let actionsArrayMinimal = alarm.isSnooze ? [UIUserNotificationAction](arrayLiteral: snoozeAction, stopAction) : [UIUserNotificationAction](arrayLiteral: stopAction)
        
        // Notification Category.
        let alarmCategory = UIMutableUserNotificationCategory()
        alarmCategory.identifier = Identifier.localNotificationCategory
        alarmCategory.setActions(actionsArray, for: .default)
        alarmCategory.setActions(actionsArrayMinimal, for: .minimal)
        let categoriesForSettings = Set(arrayLiteral: alarmCategory)
        
        // Notification Settings.
        let newNotificationSettings = UIUserNotificationSettings(types: notificationTypes, categories: categoriesForSettings)
        UIApplication.shared.registerUserNotificationSettings(newNotificationSettings)
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
        notification.category = Identifier.localNotificationCategory
        notification.soundName = UILocalNotificationDefaultSoundName
        notification.timeZone = TimeZone.current
        
        var dateComponents = Calendar.current.dateComponents([.hour, .minute], from: alarm.date)
        let fireDate = Calendar.current.date(from: dateComponents)
        
        //repeat weekly if repeat weekdays are selected
        switch alarm.weekday {
        case WeekdayOptions.none:   // Once.
            notification.fireDate = fireDate
            UIApplication.shared.scheduleLocalNotification(notification)
        case WeekdayOptions.all:    // Repeat Every Weekday.
            notification.repeatInterval = NSCalendar.Unit.day
            notification.fireDate = fireDate
            UIApplication.shared.scheduleLocalNotification(notification)
        default:                    // Repeat Each Weekday.
            for weekday in 0 ... 6 {
                if alarm.weekday.contains(WeekdayOptions(rawValue: 1 << weekday)) {
                    notification.userInfo = ["identifier": "\(alarm.id)\(weekday)"]
                    notification.repeatInterval = NSCalendar.Unit.weekOfYear
                    dateComponents.weekday = weekday
                    notification.fireDate = fireDate
                    UIApplication.shared.scheduleLocalNotification(notification)
                }
            }
        }
        self.setupNotification(alarm: alarm)
    }
    
}

//
//  AppDelegate.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 4..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit
import AVFoundation
import NaverSpeech


@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?
    
    private struct ShortcutItemType {
        static let nextAlarm = "com.boostCamp.ios.DreamRecorder.nextAlarm"
        static let addDream = "com.boostCamp.ios.DreamRecorder.addDream"
    }
    
    func application(_ application: UIApplication, performActionFor shortcutItem: UIApplicationShortcutItem, completionHandler: @escaping (Bool) -> Void) {
        
        // Handle Quick Action.
        if shortcutItem.type == ShortcutItemType.nextAlarm {
            AlarmScheduler.shared.nextTriggerDate(completionHandler: { (identifier, date) in
                guard let alarmIdentifier = identifier else { return }
                guard let nextAlarm = AlarmDataStore.shared.alarm(withNotificationIdentifier: alarmIdentifier) else { return }
                
                DispatchQueue.main.async {
                    self.presentAlarmStateViewController(withAlertAlarm: nextAlarm)
                    completionHandler(true)
                }
            })
        } else {
            if let addDreamNavicationController = AddDreamNavigationController.storyboardInstance() {
                
                DispatchQueue.main.async {
                    
                    var lastViewController: UIViewController? = self.window?.rootViewController
                    
                    while lastViewController?.presentedViewController != nil {
                        lastViewController = lastViewController?.presentedViewController
                    }
                    
                    if let topViewController = lastViewController,
                        type(of: topViewController) != AlarmStateViewController.self {
                        topViewController.present(addDreamNavicationController, animated: true, completion: nil)
                    }
                }
            }
        }
    }

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Register Quick action.
        let alarmIcon = UIApplicationShortcutIcon(type: .alarm)
        let nextAlarmItem = UIApplicationShortcutItem(type: ShortcutItemType.nextAlarm,
                                             localizedTitle: "Next Alarm".localized,
                                             localizedSubtitle: nil,
                                             icon: alarmIcon, userInfo: nil)
        
        let dreamIcon = UIApplicationShortcutIcon(type: .compose)
        let addDreamItem = UIApplicationShortcutItem(type: ShortcutItemType.addDream,
                                                     localizedTitle: "Add Dream".localized,
                                                     localizedSubtitle: nil,
                                                     icon: dreamIcon,
                                                     userInfo: nil)
        
        UIApplication.shared.shortcutItems = [nextAlarmItem, addDreamItem]

        // Apply Theme.
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName : UIColor.dreamTextColor1], for: .normal)
        UINavigationBar.appearance().tintColor = UIColor.white
        
        UISearchBar.appearance().barTintColor = UIColor.dreamBackgroundColor
        UISearchBar.appearance().tintColor = UIColor.white
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.white
        UIApplication.shared.statusBarStyle = .lightContent
        

        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord, with: .mixWithOthers)
            try audioSession.setActive(true)
        } catch {
        }

        // - Set UserNotification Delegate.
        if #available(iOS 10.0, *) {
            /// iOS 10.x can receive notification response by confirm to UNUserNotificationCenterDelegate.
            UNUserNotificationCenter.current().delegate = self
        } else {
            /// iOS 9.x can receive AppDelegate`s methods.
        }
        

        // - Set Dream.
        DreamDataStore.shared.createTable()
        
        if let firstDayOfCurrentMonth = DateParser().firstDayOfMonth(date: Date()) {
            DreamDataStore.shared.select(period: (firstDayOfCurrentMonth, Date()))
        }
        
        /// SoundManagerAlarmPlayerDidStart 노티피케이션을 등록한다. (SoundManager -> AppDelegate(for UI))
        /// 만약 알람이 울리면 AppDelegate는 최상위 뷰(현재 보여지고 있는 창)에 AlertingViewController를 띄운다.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.presentAlarmAlertViewController(withAlertAlarm:)),
                                               name: .SoundManagerAlarmPlayerDidStart,
                                               object: nil)
        
        /// SoundManager, DataStore, Scheduler순으로 싱글톤을 메모리에 로드한다.
        ///
        /// Scheduler의 이니셜라이저에서 남아있는 알람을 계산해서 바뀔 필요가 있는 알람을 DataStore에게 알려준다.
        /// Shceduler의 이니셜라이저에서 알람을 계산 후 다음알람을 SoundManager에게 알려준다.
        /// 따라서 Scheduler를 가장 나중에 메모리에 로드한다.
        SoundManager.shared.awake()
        AlarmDataStore.shared.awake()
        AlarmScheduler.shared.awake()

        return true
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        if (SoundManager.shared.isPlayingAlarm) {
            /// 설정된 알람이 울릴 때 앱을 실행.
            if let nextAlarm = SoundManager.shared.nextAlarm {
                self.presentAlarmAlertViewController(withAlertAlarm: nextAlarm)
            } else {
                /// Snooze알람이 울릴 때 앱을 실행.
                
            }
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        AlarmScheduler.shared.createAlertNotificationForAppWillTerminate()
        AlarmScheduler.shared.duplicateNotificationForNextAlarm()
    }
}

import UserNotifications

extension AppDelegate: UNUserNotificationCenterDelegate {
    // Handle LocalNotification.
    func application(_ application: UIApplication, didReceive notification: UILocalNotification) {
        print("Local - didReceive")
    }
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, completionHandler: @escaping () -> Void) {
        print("Local - actionHandler")
    }
    
    func application(_ application: UIApplication, handleActionWithIdentifier identifier: String?, for notification: UILocalNotification, withResponseInfo responseInfo: [AnyHashable : Any], completionHandler: @escaping () -> Void) {
        print("Local - completionHandler")
    }

    // Handle UserNotification.
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, willPresent notification: UNNotification, withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        print("User - present")
        
        guard let alertingAlarm = AlarmDataStore.shared.alarm(withNotificationIdentifier: notification.request.identifier) else { return }
        self.presentAlarmAlertViewController(withAlertAlarm: alertingAlarm)
        
        if alertingAlarm.weekday == .none {
            alertingAlarm.isActive = false
        }
        AlarmDataStore.shared.updateAlarm(alarm: alertingAlarm)
        
        completionHandler([.alert, .sound])
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("User - response")
        
        guard let alertingAlarm = AlarmDataStore.shared.alarm(withNotificationIdentifier: response.notification.request.identifier) else { return }
        
        if response.actionIdentifier == AlarmIdentifier.NotificationAction.snooze {
            AlarmScheduler.shared.createSnoozeNotification(for: alertingAlarm)
//            SoundManager.shared.pauseAlarm()
        } else if response.actionIdentifier == AlarmIdentifier.NotificationAction.stop {
            SoundManager.shared.pauseAlarm()
        } else {
            guard let alertingAlarm = AlarmDataStore.shared.alarm(withNotificationIdentifier: response.notification.request.identifier) else { return }
            self.presentAlarmAlertViewController(withAlertAlarm: alertingAlarm)
        }

        completionHandler()
    }
}


extension AppDelegate {
    @objc fileprivate func presentAlarmAlertViewController(withAlertAlarm alarm: Alarm) {
        guard let alarmAlertViewController = AlarmAlertViewController.storyboardInstance() else { return }
        alarmAlertViewController.modalTransitionStyle = .crossDissolve
        alarmAlertViewController.alertAlarm = alarm
        
        var lastViewController: UIViewController? = self.window?.rootViewController
        
        while lastViewController?.presentedViewController != nil {
            lastViewController = lastViewController?.presentedViewController
        }
        
        if let topViewController = lastViewController,
            type(of: topViewController) != AlarmAlertViewController.self {
            /// 현재 보여지고 있는 창 topViewController가 새로운 알람 울리는 창을 띄운다.
            topViewController.present(alarmAlertViewController, animated: true, completion: nil)
        } else if let topViewController = lastViewController,
            type(of: topViewController) == AlarmAlertViewController.self {
            /// 이전에 울린 알람이 존재하여 스누즈 중간에 다른 알람이 울릴 경우 울리는 창 위에 새롭게 추가로 띄운다.
            guard let previousAlarmAlertViewController = topViewController as? AlarmAlertViewController else { return }
            if previousAlarmAlertViewController.alertAlarm?.id != alarm.id {
               previousAlarmAlertViewController.present(alarmAlertViewController, animated: true, completion: nil)
            }
        }
    }
    
    fileprivate func presentAlarmStateViewController(withAlertAlarm alarm: Alarm) {
        guard let alarmStateViewController = AlarmStateViewController.storyboardInstance() else { return }
        alarmStateViewController.currentAlarm = alarm
        alarmStateViewController.modalTransitionStyle = .crossDissolve
        alarmStateViewController.shouldAnimatedTransitioning = false
        
        var lastViewController: UIViewController? = self.window?.rootViewController
        
        while lastViewController?.presentedViewController != nil {
            lastViewController = lastViewController?.presentedViewController
        }
        
        if let topViewController = lastViewController,
            type(of: topViewController) != AlarmStateViewController.self {
            topViewController.present(alarmStateViewController, animated: true, completion: nil)
        }
    }
}

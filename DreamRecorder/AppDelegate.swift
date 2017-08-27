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

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        

        // Apply Theme.
        
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName : UIColor.defaultButtonTitleColor], for: .normal)
        UINavigationBar.appearance().tintColor = UIColor.white
        
        UISearchBar.appearance().barTintColor = UIColor.dreamDefaultBackgroundColor
        UISearchBar.appearance().tintColor = UIColor.white
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.white
        UIApplication.shared.statusBarStyle = .lightContent
        
        
        let audioSession = AVAudioSession.sharedInstance()
        
        do {
            try audioSession.setCategory(AVAudioSessionCategoryPlayback, with: .mixWithOthers)
            try audioSession.setActive(true)
        } catch {
        }

        if #available(iOS 10.0, *) {
            
            UNUserNotificationCenter.current().delegate = self
//            UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
            UNUserNotificationCenter.current().getPendingNotificationRequests(completionHandler: { (requests) in
                for request in requests {
                    print("\(request.identifier)")
                }
//                print("User Noti Count: \(requests.count)")
            })
        } else {
            guard let notifications = UIApplication.shared.scheduledLocalNotifications else { return true }
            print("Local Noti Count: \(notifications.count)")
            // from LocalNotification to UNNotification.
        }
        
        
        UserDefaults.standard.set(NSKRecognizerLanguageCode.korean.rawValue, forKey: "language")
        DreamDataStore.shared.select(period: (Date(), Date()))
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.presentAlarmAlertViewController(withAlertAlarm:)), name: Notification.Name.SoundManagerAlarmPlayerDidStart, object: nil)
        
        SoundManager.shared.awake()
        AlarmDataStore.shared.awake()
        AlarmScheduler.shared.awake()
        
//        AlarmScheduler.shared.handleSoundManagerDidPlayAlarmToEnd()
        
        // Apply Theme.
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName : UIColor.defaultButtonTitleColor], for: .normal)
        UINavigationBar.appearance().tintColor = UIColor.white
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
        AlarmScheduler.shared.duplicateNotificationForNextAlarm()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        print("willEndeter")
        if (SoundManager.shared.isPlayingAlarm) {
            if let nextAlarm = SoundManager.shared.nextAlarm {
                self.presentAlarmAlertViewController(withAlertAlarm: nextAlarm)
            }
            
        }
    }

    func applicationDidBecomeActive(_ application: UIApplication) {
        // Restart any tasks that were paused (or not yet started) while the application was inactive. If the application was previously in the background, optionally refresh the user interface.
//        AlarmDataStore.shared.syncAlarmAndNotification()
    }

    func applicationWillTerminate(_ application: UIApplication) {
        // Called when the application is about to terminate. Save data if appropriate. See also applicationDidEnterBackground:.
        
        // Duplicate Notification.
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
        self.presentAlarmAlertViewController(withAlertAlarm: alertingAlarm)
        
        completionHandler()
    }
}


extension AppDelegate {
    func presentAlarmAlertViewController(withAlertAlarm alarm: Alarm) {
        guard let alarmAlertViewController = AlarmAlertViewController.storyboardInstance() else { return }
        alarmAlertViewController.modalTransitionStyle = .crossDissolve
        alarmAlertViewController.alertAlarm = alarm
        
        var lastViewController: UIViewController? = self.window?.rootViewController
        
        while lastViewController?.presentedViewController != nil {
            lastViewController = lastViewController?.presentedViewController
        }
        
        if let topViewController = lastViewController,
            type(of: topViewController) != AlarmAlertViewController.self {
            topViewController.present(alarmAlertViewController, animated: true, completion: nil)
        }
    }
}

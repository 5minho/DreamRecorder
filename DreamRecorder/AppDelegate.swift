//
//  AppDelegate.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 4..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit
import AVFoundation

@UIApplicationMain
class AppDelegate: UIResponder, UIApplicationDelegate {

    var window: UIWindow?

    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?) -> Bool {
        // Override point for customization after application launch.
        

        // Apply Theme.
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName : UIColor.defaultButtonTitleColor], for: .normal)
        UINavigationBar.appearance().tintColor = UIColor.white
        UISearchBar.appearance().barTintColor = UIColor.dreamPink
        UISearchBar.appearance().tintColor = UIColor.white
        UITextField.appearance(whenContainedInInstancesOf: [UISearchBar.self]).tintColor = UIColor.white


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

        
        DreamDataStore.shared.createTable()
        DreamDataStore.shared.selectAll()
        
        SoundManager.shared.awake()
        AlarmDataStore.shared.awake()
        AlarmScheduler.shared.awake()
        
        AlarmScheduler.shared.handleSoundManagerDidPlayAlarmToEnd()
        
        // Apply Theme.
        UIBarButtonItem.appearance().setTitleTextAttributes([NSForegroundColorAttributeName : UIColor.defaultButtonTitleColor], for: .normal)
        UINavigationBar.appearance().tintColor = UIColor.white
        
        return true
    }

    func applicationWillResignActive(_ application: UIApplication) {
        // Sent when the application is about to move from active to inactive state. This can occur for certain types of temporary interruptions (such as an incoming phone call or SMS message) or when the user quits the application and it begins the transition to the background state.
        // Use this method to pause ongoing tasks, disable timers, and invalidate graphics rendering callbacks. Games should use this method to pause the game.
//        AlarmDataStore.shared.scheduler.soundManager.registerBackgroundSoundToAlarm()
//        AlarmDataStore.shared.scheduler.duplicateNotificationByFollowingAlarm()
    }

    func applicationDidEnterBackground(_ application: UIApplication) {
        // Use this method to release shared resources, save user data, invalidate timers, and store enough application state information to restore your application to its current state in case it is terminated later.
        // If your application supports background execution, this method is called instead of applicationWillTerminate: when the user quits.
    }

    func applicationWillEnterForeground(_ application: UIApplication) {
        // Called as part of the transition from the background to the active state; here you can undo many of the changes made on entering the background.
        if (SoundManager.shared.isPlayingAlarm) {
            guard let alarmAlertViewController = AlarmAlertViewController.storyboardInstance() else { return }
            alarmAlertViewController.modalTransitionStyle = .crossDissolve
            alarmAlertViewController.alertAlarm = SoundManager.shared.nextAlarm
            self.window?.rootViewController?.present(alarmAlertViewController, animated: true, completion: nil)
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
        print(notification.category)
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
        AlarmScheduler.shared.inactivateAlarmIfNeeded()
//        NotificationCenter.default.post(name: Notification.Name.ApplicationWillPresentNotification,
//                                        object: nil,
//                                        userInfo: ["identifier": notification.request.identifier])
        
        guard let alarmAlertViewController = AlarmAlertViewController.storyboardInstance() else { return }
        alarmAlertViewController.modalTransitionStyle = .crossDissolve
        alarmAlertViewController.alertAlarm = AlarmDataStore.shared.alarm(withNotificationIdentifier: notification.request.identifier)
        self.window?.rootViewController?.present(alarmAlertViewController, animated: true, completion: nil)
        
        completionHandler([.alert, .sound])
    }
    
    @available(iOS 10.0, *)
    func userNotificationCenter(_ center: UNUserNotificationCenter, didReceive response: UNNotificationResponse, withCompletionHandler completionHandler: @escaping () -> Void) {
        print("User - response")
//        NotificationCenter.default.post(name: Notification.Name.ApplicationDidReceiveResponse,
//                                        object: nil,
//                                        userInfo: ["identifier": response.notification.request.identifier,
//                                                   "actionIdentifier": response.actionIdentifier])
        guard let alarmAlertViewController = AlarmAlertViewController.storyboardInstance() else { return }
        alarmAlertViewController.modalTransitionStyle = .crossDissolve
        alarmAlertViewController.alertAlarm = AlarmDataStore.shared.alarm(withNotificationIdentifier: response.notification.request.identifier)
        self.window?.rootViewController?.present(alarmAlertViewController, animated: true, completion: nil)
        
        completionHandler()
    }
    
}


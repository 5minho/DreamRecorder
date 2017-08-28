//
//  TodayViewController.swift
//  DreamRecorderToday
//
//  Created by JU HO YOON on 2017. 8. 24..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit
import NotificationCenter
import UserNotifications

class TodayViewController: UIViewController, NCWidgetProviding {
    
    // MARK: - Properties.
    // - Subviews.
    @IBOutlet weak var leftTimeLabel: UILabel!
    @IBOutlet weak var nextAlarmLoadingView: UIActivityIndicatorView!
    
    // - Internal.
    private var timer: Timer?
    private var nextTriggerDate: Date? {
        didSet {
            self.nextAlarmLoadingView.stopAnimating()
            self.nextAlarmLoadingView.isHidden = true
        }
    }
    
    // MARK: - View Cycle.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.nextAlarmLoadingView.startAnimating()
        
        let newTimer = Timer.scheduledTimer(timeInterval: 1,
                                            target: self,
                                            selector: #selector(self.updateLeftTimeLabelIfNeeded(sender:)),
                                            userInfo: nil,
                                            repeats: true)
        self.timer = newTimer
        RunLoop.main.add(newTimer, forMode: .UITrackingRunLoopMode)
    }
    
    
    /// nextTriggerDate를 확인하여 leftTimeLabel을 메인 스레드에서 변경한다.
    @objc private func updateLeftTimeLabelIfNeeded(sender: Timer) {
        
        self.nextTriggerDate(withIdentifier: nil) {
            
            (identifier, nextTriggerDate) in
            
            DispatchQueue.main.async {
                self.nextTriggerDate = nextTriggerDate
                self.updateLeftTimeLabel()
            }
        }
    }
    
    /// 현재 프로퍼티로 가지고 있는 nextTriggerDate와 현재시간을 비교하여 leftTimeLabel의 text를 변경한다.
    private func updateLeftTimeLabel() {
        if let nextTriggerDate = self.nextTriggerDate {
            
            let dateComponents = Calendar.current.dateComponents([.day, .hour, .minute, .second],
                                                                 from: Date(),
                                                                 to: nextTriggerDate)
            guard let day = dateComponents.day,
                var hour = dateComponents.hour,
                let minute = dateComponents.minute,
                let second = dateComponents.second
                else {
                    return
            }
            
            hour += day * 24
            
            let numberFormatter = NumberFormatter()
            numberFormatter.positiveFormat = "00"
            
            var leftTimeString = ""
            leftTimeString += "\(numberFormatter.string(from: NSNumber(value: hour)) ?? "00"):"
            leftTimeString += "\(numberFormatter.string(from: NSNumber(value: minute)) ?? "00"):"
            leftTimeString += "\(numberFormatter.string(from: NSNumber(value: second)) ?? "00")"
            
            self.leftTimeLabel.text = leftTimeString
            
        } else {
            if self.nextAlarmLoadingView.isAnimating {
                self.leftTimeLabel.text = ""
            } else {
                self.leftTimeLabel.text = "not exist."
            }
            
        }
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
        // Dispose of any resources that can be recreated.
    }
    
    func widgetPerformUpdate(completionHandler: (@escaping (NCUpdateResult) -> Void)) {
        // Perform any setup necessary in order to update the view.
        
        // If an error is encountered, use NCUpdateResult.Failed
        // If there's no update required, use NCUpdateResult.NoData
        // If there's an update, use NCUpdateResult.NewData
        
        completionHandler(NCUpdateResult.newData)
    }
    
    /// UserNotificationCenter에 등록된 Notification들 중에서 다음에 울릴 Notification의 정보를 Completion Block을 통해 전달한다.
    ///
    /// - Parameters:
    ///   - identifier: Notification을 Filter할 때 사용 될 Alarm객체 Identifier. 만약 nil값이 넘어온다면 모든 Notification들 중에서 가장 가까운 알람을 찾는다.
    ///   - completion: 다음에 울릴 Notification의 주인이 되는 Alarm객체의 Identifier와 Notification의 triggerDate가 인자로 절달된다.
    private func nextTriggerDate(withIdentifier identifier: String?, completionBlock completion: @escaping (_ identifier: String?, _ nextTriggerDate: Date?) -> Void) {
        
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getPendingNotificationRequests {
                
                (requests) in
                
                let sortedNotifications = requests.sorted(by: {
                    
                    (request1, request2) -> Bool in
                    
                    if let calendarTrigger1 = request1.trigger as? UNCalendarNotificationTrigger,
                        let calendarTrigger2 = request2.trigger as? UNCalendarNotificationTrigger,
                        let triggerDate1 = calendarTrigger1.nextTriggerDate(),
                        let triggerDate2 = calendarTrigger2.nextTriggerDate() {
                        return triggerDate1.compare(triggerDate2) == .orderedAscending
                    } else {
                        return false
                    }
                })
                
                if let calendarNotificationTrigger = sortedNotifications.first?.trigger as? UNCalendarNotificationTrigger {
                    
                    let identifier = sortedNotifications.first?.identifier
                    let nextTriggerDate = calendarNotificationTrigger.nextTriggerDate()
                    
                    completion(identifier, nextTriggerDate)
                    
                } else {
                    completion(nil, nil)
                }
            }
        } else {
            
            // TODO: Today Extension can`t access to UIApplication. Should find how to get next notification time.
            
            /*
            guard let notifications = UIApplication.shared.scheduledLocalNotifications else { return completion(nil, nil) }
            
            var filteredNotifications = notifications
            if let identifier = identifier {
                filteredNotifications = notifications.filter { ($0.userInfo?[AlarmNotificationUserInfoKey.identifier] as? String)?.contains(identifier) ?? false }
            }
            let sortedNotifications = filteredNotifications.sorted(by: > )
            
            let identifier = sortedNotifications.first?.userInfo?[AlarmNotificationUserInfoKey.identifier] as? String
            let nextTriggerDate = sortedNotifications.first?.fireDate
            
            completion(identifier, nextTriggerDate)
             */
        }
    }
    
}

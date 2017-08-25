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
    
    private var timer: Timer?
    
    @IBOutlet weak var leftTimeLabel: UILabel!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        // Do any additional setup after loading the view from its nib.
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateLeftTimeLabel(sender:)), userInfo: nil, repeats: true)
//        guard let updateTimer = self.timer else { return }
//        RunLoop.main.add(updateTimer, forMode: .commonModes)
    }
    
    func updateLeftTimeLabel(sender: Timer) {
        self.nextTriggerDate(withIdentifier: nil) { (identifier, nextTriggerDate) in
            DispatchQueue.main.async {
                if let nextTriggerDate = nextTriggerDate {
                    let dateComponents = Calendar.current.dateComponents([.day, .hour, .minute, .second],
                                                                         from: Date(),
                                                                         to: nextTriggerDate)
                    guard let day = dateComponents.day,
                        var hour = dateComponents.hour,
                        var minute = dateComponents.minute,
                        var second = dateComponents.second
                        else {
                            return
                    }
                    guard let date = Calendar.current.date(from: dateComponents) else { return }
                    
                    let dateFormatter = DateFormatter()
                    dateFormatter.dateFormat = "hh:mm:SS"
                    
                    let numberFormatter = NumberFormatter()
                    numberFormatter.positiveFormat = "00"
                    var leftTimeString = ""
                    leftTimeString += "\(numberFormatter.string(from: NSNumber(value: hour)) ?? "00"):"
                    leftTimeString += "\(numberFormatter.string(from: NSNumber(value: minute)) ?? "00"):"
                    leftTimeString += "\(numberFormatter.string(from: NSNumber(value: second)) ?? "00")"
                    self.leftTimeLabel.text = leftTimeString
//                    self.leftTimeLabel.text = "\(hour):\(minute):\(second)"
                } else {
                    self.leftTimeLabel.text = "not exist."
                }
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
    
    private func nextTriggerDate(withIdentifier identifier: String?, completionBlock completion: @escaping (_ identifier: String?, _ nextTriggerDate: Date?) -> Void) {
        if #available(iOS 10.0, *) {
            UNUserNotificationCenter.current().getPendingNotificationRequests {
                
                (requests) in
                
                let sortedNotifications = requests.sorted(by: { (request1, request2) -> Bool in
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
//            
//            guard let notifications = UIApplication.shared.scheduledLocalNotifications else { return completion(nil, nil) }
//            
//            var filteredNotifications = notifications
//            if let identifier = identifier {
//                filteredNotifications = notifications.filter { ($0.userInfo?[AlarmNotificationUserInfoKey.identifier] as? String)?.contains(identifier) ?? false }
//            }
//            let sortedNotifications = filteredNotifications.sorted(by: > )
//            
//            let identifier = sortedNotifications.first?.userInfo?[AlarmNotificationUserInfoKey.identifier] as? String
//            let nextTriggerDate = sortedNotifications.first?.fireDate
//            
//            completion(identifier, nextTriggerDate)
        }
    }
    
}

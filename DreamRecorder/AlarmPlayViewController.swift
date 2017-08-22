//
//  AlarmPlayViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 16..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit
import UserNotifications

class AlarmPlayViewController: UIViewController {

    @IBOutlet weak var alarmTimeLabel: UILabel!
    @IBOutlet weak var leftTimeLabel: UILabel!
    
    var dateFormmater: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm:ss"
        return dateFormatter
    }()
    var shouldCustomTransition: Bool = true
    var playingAlarm: Alarm?
    var timer: Timer?
    
    weak var presentingDelegate: CellExpandAnimatorPresentingDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.alarmDefaultBackgroundColor
        self.alarmTimeLabel.textColor = UIColor.alarmDarkText
        self.leftTimeLabel.textColor = UIColor.alarmLightText
        self.alarmTimeLabel.font = UIFont.title1
        self.leftTimeLabel.font = UIFont.title3
        
        if shouldCustomTransition {
            self.transitioningDelegate = self
        }
        
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissByGesture(sender:)))
        self.view.addGestureRecognizer(tapGestureRecognizer)
        
        self.updateLeftTimeLabel()
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateLeftTimeLabel), userInfo: nil, repeats: true)
        
        guard let playingAlarm = playingAlarm else { return }
        self.alarmTimeLabel.text = DateParser().time(from: playingAlarm.date)
    }
    
    func updateLeftTimeLabel(){
        guard let playingAlarm = playingAlarm else { return }
        
        AlarmScheduler.shared.nextTriggerDate(withAlarmIdentifier: playingAlarm.id, completionBlock: { (_, nextTriggerDate) in
            OperationQueue.main.addOperation {
                guard let nextTriggerDate = nextTriggerDate else { return }
                let dateComponents = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: Date(), to: nextTriggerDate)
                
                guard let day = dateComponents.day,
                    var hour = dateComponents.hour,
                    let minute = dateComponents.minute,
                    let second = dateComponents.second
                else {
                    return
                }
                hour += day * 24
                self.leftTimeLabel.text = "\(hour):\(minute):\(second)"
            }
        })
    }
    
    func dismissByGesture(sender: UITapGestureRecognizer){
        self.timer?.invalidate()
        self.timer = nil
        self.dismiss(animated: true, completion: nil)
    }
}

extension AlarmPlayViewController: CellExpandAnimatorPresentedDelegate {
    var presentedView: UIView {
        return self.view
    }
    
    var presentedLabel: UILabel {
        return self.alarmTimeLabel
    }
}

extension AlarmPlayViewController: UIViewControllerTransitioningDelegate {
    
    func animationController(forDismissed dismissed: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let cellExpandAnimator = CellExpandAnimator(type: .dismiss)
        cellExpandAnimator.presentingDelegate = self.presentingDelegate
        cellExpandAnimator.presentedDelegate = self
        return cellExpandAnimator
    }
    
    func animationController(forPresented presented: UIViewController, presenting: UIViewController, source: UIViewController) -> UIViewControllerAnimatedTransitioning? {
        let cellExpandAnimator = CellExpandAnimator(type: .present)
        cellExpandAnimator.presentingDelegate = source as? CellExpandAnimatorPresentingDelegate
        cellExpandAnimator.presentedDelegate = self
        return cellExpandAnimator
    }
}

extension AlarmPlayViewController {
    class func storyboardInstance() -> AlarmPlayViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmPlayViewController
    }
}

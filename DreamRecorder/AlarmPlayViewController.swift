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
    var playingAlarm: Alarm?
    var timer: Timer?
    
    weak var presentingDelegate: CellExpandAnimatorPresentingDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.transitioningDelegate = self
        let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(self.dismissByGesture(sender:)))
        self.view.addGestureRecognizer(tapGestureRecognizer)
        
        self.updateLeftTimeLabel()
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateLeftTimeLabel), userInfo: nil, repeats: true)
        
        guard let playingAlarm = playingAlarm else { return }
        self.alarmTimeLabel.text = DateParser().time(from: playingAlarm.date)
    }
    
    func updateLeftTimeLabel(){
        guard let playingAlarm = playingAlarm else { return }
        let dateComponents = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: Date(), to: playingAlarm.date)
        self.leftTimeLabel.text = "\(dateComponents.hour!):\(dateComponents.minute!):\(dateComponents.second!)"
    }
    
    func dismissByGesture(sender: UITapGestureRecognizer){
        print("DissmissbYGesture \(self.alarmTimeLabel.frame)")
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

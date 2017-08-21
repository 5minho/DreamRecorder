//
//  AlarmActionViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 20..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class AlarmAlertViewController: UIViewController {
    
    @IBOutlet weak var alarmNameLabel: UILabel!
    @IBOutlet weak var snoozeButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    var alertAlarm: Alarm?
    
    @IBAction func snoozeButtonDidTap(_ sender: UIButton) {
        defer {
            self.alarmNameLabel.layer.removeAllAnimations()
            self.startAlarmNameLabelAnimation(withDuration: 0.5)
            SoundManager.shared.pauseAlarm()
        }
        guard let snoozeAlarm = self.alertAlarm else { return }
        AlarmScheduler.shared.duplicateSnoozeNotification(for: snoozeAlarm)
    }
    
    @IBAction func stopButtonDidTap(_ sender: UIButton) {
        SoundManager.shared.pauseAlarm()
        self.dismiss(animated: true, completion: nil)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.alarmDefaultBackgroundColor
        
        self.alarmNameLabel.text = self.alertAlarm?.name
        self.alarmNameLabel.font = UIFont.title1
        self.alarmNameLabel.textColor = UIColor.alarmDarkText
        
        self.snoozeButton.backgroundColor = .alarmDefaultBackgroundColor
        self.snoozeButton.setTitleColor(.alarmButtonTitleColor, for: .normal)
        self.snoozeButton.titleLabel?.font = UIFont.title2
        
        self.stopButton.backgroundColor = .alarmDefaultBackgroundColor
        self.stopButton.setTitleColor(.alarmButtonTitleColor, for: .normal)
        self.stopButton.titleLabel?.font = UIFont.title2
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.startAlarmNameLabelAnimation(withDuration: 0.1)
    }
    
    private func startAlarmNameLabelAnimation(withDuration duration: TimeInterval) {
        self.alarmNameLabel.transform = CGAffineTransform(rotationAngle: -0.1)
        UIView.animate(withDuration: duration, delay: 0, options: [.repeat, .autoreverse], animations: {
            self.alarmNameLabel.transform = CGAffineTransform(rotationAngle: 0.2)
        }, completion: nil)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        self.alarmNameLabel.layer.removeAllAnimations()
    }
}

extension AlarmAlertViewController {
    class func storyboardInstance() -> AlarmAlertViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmAlertViewController
    }
}

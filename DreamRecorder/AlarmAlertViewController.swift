//
//  AlarmActionViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 20..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class AlarmAlertViewController: UIViewController {

    // MARK: - Properties.
    // - Subviews.
    @IBOutlet weak var alarmNameLabel: UILabel!
    @IBOutlet weak var leftTimeLabel: UILabel!
    @IBOutlet weak var snoozeButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    // - Internal.
    var alertAlarm: Alarm?
    
    // - Private.
    private var timer: Timer?
    private var snoozeStartDate: Date?
    
    // MARK: - Actions.
    @IBAction func snoozeButtonDidTap(_ sender: UIButton) {
        
        sender.isEnabled = false
        
        SoundManager.shared.pauseAlarm()
        
        guard let snoozeAlarm = self.alertAlarm else { return self.dismiss(animated: true, completion: nil) }
        
        AlarmScheduler.shared.createSnoozeNotification(for: snoozeAlarm)
        
        // 알람 시간 카운트 다운을 위한 설정.
        self.snoozeStartDate = Date().addingSnoozeTimeInterval
        self.timer = Timer.scheduledTimer(timeInterval: 1,
                                          target: self,
                                          selector: #selector(self.updateLeftTimeLabel),
                                          userInfo: nil,
                                          repeats: true)
        self.leftTimeLabel.isHidden = false
        
        // 애니메이션.
        self.alarmNameLabel.layer.removeAllAnimations()
        self.startAlarmNameLabelAnimation(withDuration: 0.5)
    }

    @IBAction func stopButtonDidTap(_ sender: UIButton) {
        
        SoundManager.shared.pauseAlarm()
        
        guard let alertingAlarm = self.alertAlarm else { return }
        
        AlarmScheduler.shared.removeSnoozeNotification(for: alertingAlarm) {
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    // MARK: - Handler.
    @objc private func updateLeftTimeLabel() {
        
        guard let snoozeStartDate = self.snoozeStartDate else { return }
        
        let dateComponents = Calendar.current.dateComponents([.day, .hour, .minute, .second], from: Date(), to: snoozeStartDate)
        
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

    // MARK: - View Cycle.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.dreamBackgroundColor
        
        self.alarmNameLabel.text = self.alertAlarm?.name
        self.alarmNameLabel.font = UIFont.title1
        self.alarmNameLabel.textColor = UIColor.alarmDarkText
        
        self.leftTimeLabel.font = UIFont.title3
        self.leftTimeLabel.textColor = UIColor.alarmLightText
        
        self.snoozeButton.backgroundColor = UIColor.dreamBackgroundColor
        self.snoozeButton.setTitleColor(UIColor.dreamTextColor1, for: .normal)
        self.snoozeButton.setTitleColor(UIColor.dreamTextColor3, for: .disabled)
        self.snoozeButton.titleLabel?.font = UIFont.title2
        
        self.stopButton.backgroundColor = .dreamBackgroundColor
        self.stopButton.setTitleColor(UIColor.dreamTextColor1, for: .normal)
        self.stopButton.titleLabel?.font = UIFont.title2
        
        self.leftTimeLabel.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        self.startAlarmNameLabelAnimation(withDuration: 0.1)
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.alarmNameLabel.layer.removeAllAnimations()
        self.alarmNameLabel.transform = .identity
    }
    
    /// 알람명을 보여주는 레이블이 시소같은 움직임을 가지는 애니메이션을 추가한다.
    ///
    /// - Parameter duration: 해당 값을 으로 Label Animation의 Duration을 설정한다.
    private func startAlarmNameLabelAnimation(withDuration duration: TimeInterval) {
        self.alarmNameLabel.transform = CGAffineTransform(rotationAngle: -0.1)
        
        UIView.animate(withDuration: duration,
                       delay: 0,
                       options: [.repeat, .autoreverse],
                       animations:
        {
            self.alarmNameLabel.transform = CGAffineTransform(rotationAngle: 0.2)
        },
                       completion: nil)
    }
}

extension AlarmAlertViewController {
    // MARK: - StoryboardInstance.
    class func storyboardInstance() -> AlarmAlertViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmAlertViewController
    }
}

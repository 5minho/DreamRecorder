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
    @IBOutlet weak var dreamRecordButton: UIButton!
    
    // - Internal.
    var alertAlarm: Alarm?
    
    // - Private.
    private var timer: Timer?
    private var snoozeStartDate: Date?
    private var shouldDismiss: Bool = false
    
    // MARK: - Actions.
    @IBAction func snoozeButtonDidTap(_ sender: UIButton) {
        /// 연속적으로 스누즈 버튼을 활성화 못하게 한다.
        sender.isEnabled = false
        
        /// 현재 울리는 알람음을 중지한다.
        SoundManager.shared.pauseAlarm()
        
        /// 현재 울리는 알람 객체를 이용하여 스누즈용 Notification을 생성한다.
        guard let snoozeAlarm = self.alertAlarm else { return self.dismiss(animated: true, completion: nil) }
        AlarmScheduler.shared.createSnoozeNotification(for: snoozeAlarm)
        
        /// 스누자 알람 시간 카운트 다운을 위한 설정.
        self.snoozeStartDate = Date().dateForAlarm.addingSnoozeTime
        self.timer = Timer.scheduledTimer(timeInterval: 1,
                                          target: self,
                                          selector: #selector(self.updateLeftTimeLabel),
                                          userInfo: nil,
                                          repeats: true)
        self.leftTimeLabel.isHidden = false
        
        /// 시소처럼 흔들리는 애니메이션의 속도를 바꾸어 준다.
        self.alarmNameLabel.layer.removeAllAnimations()
        self.startAlarmNameLabelAnimation(withDuration: 0.5)
    }

    @IBAction func stopButtonDidTap(_ sender: UIButton) {
        /// 현재 울리는 알람음을 중지한다.
        SoundManager.shared.pauseAlarm()
        
        /// 현재 울리는 알람 객체를 이용하여 스누즈용 Notification을 제거한다.
        guard let alertingAlarm = self.alertAlarm else { return }
        AlarmScheduler.shared.removeSnoozeNotification(for: alertingAlarm) {
            DispatchQueue.main.async {
                self.dismiss(animated: true, completion: nil)
            }
        }
    }
    
    @IBAction func dreamRecordButton(_ sender: UIButton) {
        /// 현재 울리는 알람음을 중지한다.
        SoundManager.shared.pauseAlarm()
        
        /// AddDreamNavigationController를 현재 ViewController에서 present한다.
        guard let addDreamNavigationController = AddDreamNavigationController.storyboardInstance() else { return }
        self.present(addDreamNavigationController, animated: true, completion: {
            self.shouldDismiss = true
        })
    }
    
    // MARK: - Handler.
    @objc private func updateLeftTimeLabel() {
        guard let snoozeStartDate = self.snoozeStartDate else { return }
        self.leftTimeLabel.text = snoozeStartDate.dateForAlarm.descriptionForLeftTime
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
        self.snoozeButton.setTitleColor(UIColor.dreamTextColor2, for: .normal)
        self.snoozeButton.setTitleColor(UIColor.dreamTextColor3, for: .disabled)
        self.snoozeButton.titleLabel?.font = UIFont.callout
        
        self.stopButton.backgroundColor = .dreamBackgroundColor
        self.stopButton.setTitleColor(UIColor.dreamTextColor2, for: .normal)
        self.stopButton.titleLabel?.font = UIFont.callout
        
        self.dreamRecordButton.backgroundColor = .dreamBackgroundColor
        self.dreamRecordButton.setTitleColor(UIColor.dreamTextColor1, for: .normal)
        self.dreamRecordButton.titleLabel?.font = UIFont.title1
        
        self.leftTimeLabel.isHidden = true
        
        /// ViewCycle(화면전환)이외의 AppCycle에 따른 애니메이션처리는 Notification Center를 통해 관리해주어야 한다.
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.startAlarmNameLabelAnimation(withDuration:)),
                                               name: Notification.Name.UIApplicationWillEnterForeground,
                                               object: nil)
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.cancelAlarmNameLabelAnimation),
                                               name: Notification.Name.UIApplicationWillResignActive,
                                               object: nil)
    }
    
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        
        self.startAlarmNameLabelAnimation(withDuration: 0.1)
        
        /// AlarmAlertViewController는 AddDreamViewConroller를 띄울 수 있는데
        /// 이때 꿈 입력이 끝나면 AlarmAlertViewController도 사라져야한다.
        if self.shouldDismiss {
            self.dismiss(animated: false, completion: nil)
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        self.cancelAlarmNameLabelAnimation()
    }
    
    // MARK: - Methods.
    /// 알람명을 보여주는 레이블이 시소같은 움직임을 가지는 애니메이션을 추가한다.
    ///
    /// - Parameter duration: 해당 값을 으로 Label Animation의 Duration을 설정한다.
    @objc private func startAlarmNameLabelAnimation(withDuration duration: TimeInterval) {
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
    
    /// 알람명을 보여주는 레이블이 시소같은 움직임을 가지는 애니메이션을 정지(삭제)한다.
    @objc private func cancelAlarmNameLabelAnimation() {
        self.alarmNameLabel.layer.removeAllAnimations()
        self.alarmNameLabel.transform = .identity
    }
}

extension AlarmAlertViewController {
    // MARK: - StoryboardInstance.
    class func storyboardInstance() -> AlarmAlertViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmAlertViewController
    }
}

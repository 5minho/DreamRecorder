//
//  AlarmActionViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 20..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class AlarmAlertViewController: UIViewController {

    // MARK: Properties.
    // Subviews.
    @IBOutlet weak var alarmNameLabel: UILabel!
    @IBOutlet weak var leftTimeLabel: UILabel!
    @IBOutlet weak var snoozeButton: UIButton!
    @IBOutlet weak var stopButton: UIButton!
    
    // Internal.
    var alertAlarm: Alarm?
    
    // Private.
    private var timer: Timer?
    private var snoozeStartDate: Date?
    
    // MARK: Actions.
    @IBAction func snoozeButtonDidTap(_ sender: UIButton) {
        
        sender.isEnabled = false
        
        guard let snoozeAlarm = self.alertAlarm else { return self.dismiss(animated: true, completion: nil) }
        
        AlarmScheduler.shared.duplicateSnoozeNotification(for: snoozeAlarm)
        
        self.snoozeStartDate = Date().addingSnoozeTimeInterval
        self.timer = Timer.scheduledTimer(timeInterval: 1, target: self, selector: #selector(self.updateleftTimeLabel), userInfo: nil, repeats: true)
        
        self.leftTimeLabel.isHidden = false
        
        self.alarmNameLabel.layer.removeAllAnimations()
        self.startAlarmNameLabelAnimation(withDuration: 0.5)
        SoundManager.shared.pauseAlarm()
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
    
    // Handler.
    func updateleftTimeLabel() {
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

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.alarmDefaultBackgroundColor
        
        self.alarmNameLabel.text = self.alertAlarm?.name
        self.alarmNameLabel.font = UIFont.title1
        self.alarmNameLabel.textColor = UIColor.alarmDarkText
        
        self.leftTimeLabel.font = UIFont.title3
        self.leftTimeLabel.textColor = UIColor.alarmLightText
        
        self.snoozeButton.backgroundColor = .alarmDefaultBackgroundColor
        self.snoozeButton.setTitleColor(.alarmButtonTitleColor, for: .normal)
        self.snoozeButton.setTitleColor(UIColor.alarmText, for: .disabled)
        self.snoozeButton.titleLabel?.font = UIFont.title2
        
        self.stopButton.backgroundColor = .alarmDefaultBackgroundColor
        self.stopButton.setTitleColor(.alarmButtonTitleColor, for: .normal)
        self.stopButton.titleLabel?.font = UIFont.title2
        
        self.leftTimeLabel.isHidden = true
    }
    
    override func viewDidAppear(_ animated: Bool) {
        print(#function)
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
        self.alarmNameLabel.transform = .identity
        
    }
}

extension AlarmAlertViewController {
    class func storyboardInstance() -> AlarmAlertViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmAlertViewController
    }
}

protocol Testable {
    func GoodBye()
    func testHello()
}

// Extension + Where
extension Testable where Self: UIViewController {
    func GoodBye() {
        
    }
    func testHello() {
        self.view.addSubview(UIView())
    }
}

extension UIViewController {
    func test2(){
        
    }
}

extension UIView: Testable {
    func testHello() {
        
    }

    func GoodBye() {
        
    }

    
}
extension AlarmAlertViewController {
    override func viewDidLayoutSubviews() {
        self.test2()
    }
}

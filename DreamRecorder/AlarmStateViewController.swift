//
//  AlarmPlayViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 16..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit
import UserNotifications

protocol AlarmStateViewControllerDelegate: NSObjectProtocol {
    func alarmStateViewController(_ controller: AlarmStateViewController, didActivePrewviewAction alarm: Alarm)
    func alarmStateViewController(_ controller: AlarmStateViewController, didDeletePrewviewAction alarm: Alarm)
}

class AlarmStateViewController: UIViewController {

    // MARK: - Properties.
    // - Subviews.
    @IBOutlet weak var alarmTimeLabel: UILabel!
    @IBOutlet weak var leftTimeLabel: UILabel!
    @IBOutlet weak var hintLabel: UILabel!
    
    // - Private.
    fileprivate var animatorInteractor = AnimatorInteractor()
    private var timer: Timer?
    private var dateFormmater: DateFormatter = {
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "hh:mm:ss"
        return dateFormatter
    }()
    
    // - Internal.
    var currentAlarm: Alarm?
    weak var delegate: AlarmStateViewControllerDelegate?
    var shouldAnimatedTransitioning = true
    weak var presentingDelegate: CellExpandAnimatorPresentingDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        /// Apply Alarm Theme.
        self.view.backgroundColor = UIColor.dreamBackgroundColor
        self.alarmTimeLabel.font = UIFont.title1
        self.alarmTimeLabel.textColor = UIColor.dreamTextColor1
        self.leftTimeLabel.font = UIFont.title3
        self.leftTimeLabel.textColor = UIColor.dreamTextColor3
        self.hintLabel.font = UIFont.callout
        self.hintLabel.textColor = UIColor.dreamTextColor2
        
        if self.shouldAnimatedTransitioning {
            self.transitioningDelegate = self
        }
        
        let panGestureRecognizer = UIPanGestureRecognizer(target: self,
                                                          action: #selector(self.handlePanGestureRecognizer(sender:)))
        self.view.addGestureRecognizer(panGestureRecognizer)
        
        guard let currentAlarm = self.currentAlarm else { return }
        
        self.alarmTimeLabel.text = DateParser().time(from: currentAlarm.date)
        
        self.updateLeftTimeLabel()
        
        self.timer = Timer.scheduledTimer(timeInterval: 1,
                                          target: self,
                                          selector: #selector(self.updateLeftTimeLabel),
                                          userInfo: nil,
                                          repeats: true)
    }
    
    /// 남은시간을 보여주는 레이블의 텍스트를 현재시간과 해당 알람의 다음에 울릴 시간의 차이를 DateComponent를 통해 테스트로 변환한다.
    ///
    /// 알람의 다음 울릴 시간은 AlarmScheduler에 접근하여 nextTriggerDate를 가져와서
    /// AlarmScheduler에서 UserNotification의 Notification들을 가져와 비교할 때 메인이 아닌 스레드에서 발생하므로
    /// nextTrigerDate를 얻은 후에 Label(UI)업데이트는 메인 스레드로 돌린다.
    ///
    /// 반복이 없는 알람의 경우 한번 울린 후에는 00:00:00에서 멈추게 된다.
    func updateLeftTimeLabel(){
        
        guard let currentAlarm = self.currentAlarm else { return }
        
        AlarmScheduler.shared.nextTriggerDate(withAlarmIdentifier: currentAlarm.id)
        { (_, nextTriggerDate) in
            
            guard let nextTriggerDate = nextTriggerDate else { return }
            
            OperationQueue.main.addOperation {
                
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
                self.leftTimeLabel.text = "\(hour):\(minute):\(second)"
            }
        }
    }
    
    /// 사용자가 Swipe할 때 불려지는 메서드.
    ///
    /// UIPanGestureRecognizer를 통해서 사용자가 움직인 거리값을 기준으로 화면을 Dismiss할 지 결정한다.
    ///
    /// 또한 터치 이동거리가 전체 화면에서 0.3퍼센트(threshold)가 넘지 않을 경우 dismissTrnasition을 취소한다.
    /// - Parameter sender: 해당 UIPanGestureRecognizer를 통해서 사용자가 Swipe의 정도를 판단한다.
    @objc private func handlePanGestureRecognizer(sender: UIPanGestureRecognizer) {
        
        let percentThreshold: CGFloat = 0.3
        
        let translation = sender.translation(in: self.view)
        
        var xMovementPercent = translation.x / self.view.frame.width
        var yMovementPercent = translation.y / self.view.frame.height
        
        xMovementPercent = abs(xMovementPercent)
        yMovementPercent = abs(yMovementPercent)
        
        let movementPercent = max(xMovementPercent, yMovementPercent)
        
        switch sender.state {
        case .began:
            
            self.animatorInteractor.hasStarted = true
            self.dismiss(animated: true, completion: nil)
            
        case .changed:
            
            self.animatorInteractor.shouldFinish = (movementPercent > percentThreshold)
            self.animatorInteractor.update(movementPercent)
            
        case .cancelled:
            
            self.animatorInteractor.hasStarted = false
            self.animatorInteractor.update(0)
            self.animatorInteractor.cancel()
            
        case .ended:
            
            self.animatorInteractor.hasStarted = false
            
            if self.animatorInteractor.shouldFinish {
                
                self.timer?.invalidate()
                self.timer = nil
                self.animatorInteractor.finish()
                
            } else {
                
                self.animatorInteractor.update(0)
                self.animatorInteractor.cancel()
            }
            
        default:
            // possible and failed state.
            break
        }
    }
}

extension AlarmStateViewController {
    override var previewActionItems: [UIPreviewActionItem] {
        
        guard let currentAlarm = self.currentAlarm else { return [] }
        
        if currentAlarm.isActive {
            let deletePreviewAction = UIPreviewAction(title: "Delete".localized, style: .destructive) { (previewAction, viewController) in
                self.delegate?.alarmStateViewController(self, didDeletePrewviewAction: currentAlarm)
            }
            return [deletePreviewAction]
        } else {
            let activatePreviewAction = UIPreviewAction(title: "Activate".localized, style: .default) { (previewAction, viewController) in
                self.delegate?.alarmStateViewController(self, didActivePrewviewAction: currentAlarm)
            }
            let deletePreviewAction = UIPreviewAction(title: "Delete".localized, style: .destructive) { (previewAction, viewController) in
                self.delegate?.alarmStateViewController(self, didDeletePrewviewAction: currentAlarm)
            }
            return [activatePreviewAction, deletePreviewAction]
        }
    }
}

extension AlarmStateViewController: CellExpandAnimatorPresentedDelegate {
    // MARK: - CellExpandAnimatorPresentedDelegate
    var presentedView: UIView {
        return self.view
    }
    
    var presentedLabel: UILabel {
        return self.alarmTimeLabel
    }
}

extension AlarmStateViewController: UIViewControllerTransitioningDelegate {
    // MARK: - UIViewControllerTransitioningDelegate
    func interactionControllerForDismissal(using animator: UIViewControllerAnimatedTransitioning) -> UIViewControllerInteractiveTransitioning? {
        return self.animatorInteractor.hasStarted ? self.animatorInteractor : nil
    }
    
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

extension AlarmStateViewController {
    // MARK: - Storyboard Instance.
    class func storyboardInstance() -> AlarmStateViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmStateViewController
    }
}

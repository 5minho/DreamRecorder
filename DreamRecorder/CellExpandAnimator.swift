//
//  CellExpandAnimator.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 16..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

/// 화면전환의 중간 단계를 컨트롤 하기 위한 커스텀 InteractiveTransition.
///
/// TouchEvent가 끝났을 때, 움직인 거리에 의한 화면전환 여부를 결정할 수 있다.
/// PanGesture의 이동거리를 확인하고 거리가 설정된 기점을 초과하면 화면전환을 한다. 그렇지 않으면 cancel()를 호출하여 취소한다.
class AnimatorInteractor: UIPercentDrivenInteractiveTransition {
    var hasStarted = false
    var shouldFinish = false
}

/// present와 dismiss에 대한 화면전환 처리를 위한 type을 구분한다.
enum CellExpandAnimatorType {
    case present
    case dismiss
}

/// 화면을 띄우는 뷰(presenting)의 역할을 담당하게 만들어주는 delegate.
///
/// presentingView: UITableViewCell로서 화면 전환의 시작점(present시)과 끝점(dismiss시)이 될 셀을 반환해야한다.
/// presentingLabel: UITableViewCell안에 있는 UITextLabel로서 다음 화면과 겹치는 레이블을 반환해야한다.
protocol CellExpandAnimatorPresentingDelegate: NSObjectProtocol {
    var presentingView: UIView { get }
    var presentingLabel: UILabel { get }
}

/// 화면에 띄워진 뷰(presented)의 역할을 담당하게 만들어주는 delegate.
///
/// presentingView: UIViewController의 view로서 화면 전환의 시작점(dismiss시)과 끝점(present시)이 될 뷰를 반환해야한다.
/// presentingLabel: view안에 있는 UITextLabel로서 UITableViewCell에 위치한 공통의 레이블을 반환해야한다.
protocol CellExpandAnimatorPresentedDelegate: NSObjectProtocol {
    var presentedView: UIView { get }
    var presentedLabel: UILabel { get }
}

class CellExpandAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    // MARK: - Properties.
    // - Internal.
    weak var presentingDelegate: CellExpandAnimatorPresentingDelegate?
    weak var presentedDelegate: CellExpandAnimatorPresentedDelegate?
    
    // - Private.
    private let type: CellExpandAnimatorType    // Aniamtor의 역할. 이니셜라이저 단계에서 초기화 된다.
    
    // MARK: - Initializer.
    init(type: CellExpandAnimatorType) {
        self.type = type
    }
    
    // MARK: - Methods.
    /// 애니메이션 시간.
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    /// 트렌지션 애니메이션을 구현한다.
    /// TODO: 최초 어디서든 재사용이 가능하도록 제작하려 했으나 갖가지 화면들이 갖는 예외상황을 제대로 처리하지 못하고 있음.
    /// presenting과 presented Delegate들이 적절한 View와 Label를 반환해주어야한다.
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let fromViewController = transitionContext.viewController(forKey: .from)  else { return transitionContext.completeTransition(true) }
        guard let toViewController = transitionContext.viewController(forKey: .to) else { return transitionContext.completeTransition(true) }
        
        guard let presentingView = self.presentingDelegate?.presentingView else { return transitionContext.completeTransition(true) }
        guard let presentingLabel = self.presentingDelegate?.presentingLabel else { return transitionContext.completeTransition(true) }
        
        guard let presentedView = self.presentedDelegate?.presentedView else { return transitionContext.completeTransition(true) }
        guard let presentedLabel = self.presentedDelegate?.presentedLabel else { return transitionContext.completeTransition(true) }
        
        let fromView = (self.type == .present) ? presentingView : presentedView
        let fromLabel = (self.type == .present) ? presentingLabel : presentedLabel
        
        let toView = (self.type == .dismiss) ? presentingView : presentedView
        let toLabel = (self.type == .dismiss) ? presentingLabel : presentedLabel
        
        guard let fromViewInitialFrame = fromView.superview?.convert(fromView.frame, to: toViewController.view) else { return transitionContext.completeTransition(true) }
        guard let fromLabelInitialFrame = fromLabel.superview?.convert(fromLabel.frame, to: toViewController.view) else { return transitionContext.completeTransition(true) }
        
        // 트랜지션 애니메이션을 위해 Interactive뷰와 Interactive레이블을 생성한다.
        // Cell안의 textLabel을 표현할 레이블.
        // UILabel을 복사함으로서 기존의 Label에 영향을 끼치지 않도록 한다.
        let interactiveLabel = UILabel(frame: .zero)
        interactiveLabel.text = fromLabel.text
        interactiveLabel.font = fromLabel.font
        interactiveLabel.textColor = fromLabel.textColor
        interactiveLabel.textAlignment = fromLabel.textAlignment
        interactiveLabel.translatesAutoresizingMaskIntoConstraints = false
        
        // Cell을 표현할 InteractiveView와, Label을 표현할 InteractiveLabel 를 포함하는 backgroundView를 만든다.
        // InteractiveView가 변함에 따라 InteractiveLabel의 위치에 영향을 끼치지 않게하기 위해서이다.
        let backgroundView = UIView(frame: UIScreen.main.bounds)
        backgroundView.backgroundColor = UIColor.clear
        
        // Cell의 전환효과를 표현할 뷰.
        let interactiveView = UIView(frame: fromViewInitialFrame)
        interactiveView.backgroundColor = fromView.backgroundColor
        interactiveView.layer.borderColor = UIColor.dreamBorderColor.cgColor
        interactiveView.layer.borderWidth = 0.5
        interactiveView.layer.frame = interactiveView.layer.frame.insetBy(dx: -1, dy: 0)
        
        backgroundView.addSubview(interactiveView)
        backgroundView.addSubview(interactiveLabel)
        interactiveLabel.frame = fromLabelInitialFrame
        
        // 오토레이아웃에 대응 하기 위해 Constraints가 가지고 있는 constant의 변화를 통해 애니메이션을 구현해야한다.
        // Top과 Left기준으로 할 경우에는 해당 레이블의 크기가 달라질 경우에는 적절한 위치로 애니메이션이 이루이지 않는다.
        // 따라서 Label안에 Text의 위치는 Label에 센터에 위치하므로 CenterY를 기준으로 한다.
        // 또한 AutoLayout의 경우 Text의 가로 크기는 무조건 Fit하게 설정 되므로 CenterX를 기준으로 해도 문제가 되지 않는다.
        let centerXConstraint = interactiveLabel.centerXAnchor.constraint(equalTo: backgroundView.leadingAnchor, constant: fromLabelInitialFrame.origin.x + fromLabelInitialFrame.width / 2)
        let centerYConstraint = interactiveLabel.centerYAnchor.constraint(equalTo: backgroundView.topAnchor, constant: fromLabelInitialFrame.origin.y + fromLabelInitialFrame.height / 2)
        
        centerXConstraint.isActive = true
        centerYConstraint.isActive = true
        
        let transitionDuration = self.transitionDuration(using: transitionContext)
        
        if self.type == .present {
            
            transitionContext.containerView.addSubview(fromViewController.view)
            transitionContext.containerView.addSubview(backgroundView)
            transitionContext.containerView.addSubview(toViewController.view)
            toViewController.view.isHidden = true
            
            centerXConstraint.constant = toLabel.frame.origin.x + toLabel.frame.width / 2
            centerYConstraint.constant = toLabel.frame.origin.y + toLabel.frame.height / 2
            
            UIView.animate(withDuration: transitionDuration, animations: {
                
                backgroundView.layoutIfNeeded()
                interactiveView.frame = toView.frame
                
            }) { (completed) in
                
                backgroundView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                toViewController.view.isHidden = false
                
            }
        } else {
            
            if let toViewFinalFrame = toView.superview?.convert(toView.frame, to: toViewController.view),
                let toLabelFinalFrame = toLabel.superview?.convert(toLabel.frame, to: toViewController.view) {
                
                transitionContext.containerView.addSubview(toViewController.view)
                transitionContext.containerView.addSubview(backgroundView)
                
                let transitionDuration = self.transitionDuration(using: transitionContext)
                centerXConstraint.constant = toLabelFinalFrame.origin.x + toLabelFinalFrame.width / 2
                centerYConstraint.constant = toLabelFinalFrame.origin.y + toLabelFinalFrame.height / 2
                
                UIView.animate(withDuration: transitionDuration, animations: {
                    backgroundView.layoutIfNeeded()
                    interactiveView.frame = toViewFinalFrame
                    toViewController.view.alpha = 1
                    
                }) { (completed) in
                    if transitionContext.transitionWasCancelled {
                        transitionContext.containerView.addSubview(fromViewController.view)
                    }
                    
                    transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                    backgroundView.removeFromSuperview()
                }
            } else {
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                backgroundView.removeFromSuperview()
            }
        }
    }
}

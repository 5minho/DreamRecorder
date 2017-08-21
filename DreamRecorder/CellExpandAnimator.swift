//
//  CellExpandAnimator.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 16..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

enum CellExpandAnimatorType {
    case present
    case dismiss
}

protocol CellExpandAnimatorPresentingDelegate: NSObjectProtocol {
    var presentingView: UIView { get }
    var presentingLabel: UILabel { get }
}

protocol CellExpandAnimatorPresentedDelegate: NSObjectProtocol {
    var presentedView: UIView { get }
    var presentedLabel: UILabel { get }
}

class CellExpandAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    
    weak var presentingDelegate: CellExpandAnimatorPresentingDelegate?
    weak var presentedDelegate: CellExpandAnimatorPresentedDelegate?
    
    let type: CellExpandAnimatorType
    
    init(type: CellExpandAnimatorType) {
        self.type = type
    }
    
    public func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        return 0.5
    }
    
    public func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        
        guard let fromViewController = transitionContext.viewController(forKey: .from)  else { return }
        guard let toViewController = transitionContext.viewController(forKey: .to) else { return }
        
        guard let presentingView = self.presentingDelegate?.presentingView else { return }
        guard let presentingLabel = self.presentingDelegate?.presentingLabel else { return }
        
        guard let presentedView = self.presentedDelegate?.presentedView else { return }
        guard let presentedLabel = self.presentedDelegate?.presentedLabel else { return }
        
        let fromView = (self.type == .present) ? presentingView : presentedView
        let fromLabel = (self.type == .present) ? presentingLabel : presentedLabel
        
        let toView = (self.type == .dismiss) ? presentingView : presentedView
        let toLabel = (self.type == .dismiss) ? presentingLabel : presentedLabel
        
        guard let fromViewInitialFrame = fromView.superview?.convert(fromView.frame, to: toViewController.view) else { return }
        guard let fromLabelInitialFrame = fromLabel.superview?.convert(fromLabel.frame, to: toViewController.view) else { return }
        
        // Make InteractiveLabel
        // @Disscussion.
        // Copying UILabel is Not To Affect Origianl Label.
        let interactiveLabel = UILabel(frame: .zero)
        interactiveLabel.text = fromLabel.text
        interactiveLabel.font = fromLabel.font
        interactiveLabel.textColor = fromLabel.textColor
        interactiveLabel.textAlignment = fromLabel.textAlignment
        interactiveLabel.translatesAutoresizingMaskIntoConstraints = false
        
        let backgroundView = UIView(frame: UIScreen.main.bounds)
        backgroundView.backgroundColor = UIColor.clear
        
        let interactiveView = UIView(frame: fromViewInitialFrame)
        interactiveView.backgroundColor = fromView.backgroundColor
        interactiveView.layer.borderColor = UIColor.lightGray.cgColor
        interactiveView.layer.borderWidth = 0.5
        interactiveView.layer.frame = interactiveView.layer.frame.insetBy(dx: -1, dy: 0)
        
        backgroundView.addSubview(interactiveView)
        backgroundView.addSubview(interactiveLabel)
        interactiveLabel.frame = fromLabelInitialFrame
        
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
                toViewController.view.alpha = 1
            }) { (completed) in
                backgroundView.removeFromSuperview()
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
                UIView.transition(from: fromViewController.view, to: toViewController.view, duration: 0.2, options: UIViewAnimationOptions.transitionCrossDissolve, completion: nil)
                toViewController.view.isHidden = false
            }
        } else {
            
            guard let toViewFinalFrame = toView.superview?.convert(toView.frame, to: backgroundView) else { return }
            guard let toLabelFinalFrame = toLabel.superview?.convert(toLabel.frame, to: backgroundView) else { return }
            
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
                backgroundView.removeFromSuperview()
                UIView.transition(from: fromViewController.view, to: toViewController.view, duration: 0.2, options: UIViewAnimationOptions.transitionCrossDissolve, completion: nil)
                transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
            }
        }
        
        
    }
}

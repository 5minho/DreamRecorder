//
//  RecoreButton.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 15..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class RecordButton : UIButton {
    
    enum RecordState {
        case recording
        case idle
    }
    
    var recordState : RecordState = .idle {
        didSet {
            self.animate()
        }
    }

    private var radiusAnimation : CABasicAnimation = {
        var animation = CABasicAnimation(keyPath: "cornerRadius")
        animation.duration = 0.4
        return animation
    }()
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.layer.borderWidth = 1
    }
    
    func animate() {
        
        switch recordState {
            
        case .recording:
            self.startAnimation(to: self.frame.width / 2, from: 0)

        case .idle:
            self.startAnimation(to: 0, from: self.frame.width / 2)
        }
        
    }
    
    private func startAnimation(to : CGFloat, from : CGFloat) {
        self.radiusAnimation.fromValue = from
        self.radiusAnimation.toValue = to
        self.layer.add(self.radiusAnimation, forKey: "cornerRadius")
        
        UIView.animate(withDuration: self.radiusAnimation.duration) { 
            self.layer.cornerRadius = to
        }
    }

}

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

    var recordState : RecordState = .idle
    var beforeRadius : CGFloat = 0
    
    override func draw(_ rect: CGRect) {
        super.draw(rect)
        self.layer.borderWidth = 1
        beforeRadius = self.layer.cornerRadius
    }
    
    func animate() {
        
        switch recordState {
            
        case .recording:
            UIView.animate(withDuration: 3, animations: {
                self.layer.cornerRadius = self.frame.width / 2
            })
            
        case .idle:
            UIView.animate(withDuration: 3, animations: {
                self.layer.cornerRadius = self.beforeRadius
            })
            
        }
        
    }

}

//
//  SwipeableScrollView.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 14..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class SwipeableScrollView: UIScrollView {
    
    weak var customDelegate = UIResponder()
    
    
    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.customDelegate?.touchesBegan(touches, with: event)
        
    }
    
    override func touchesMoved(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.customDelegate?.touchesMoved(touches, with: event)
    }
    
    override func touchesEnded(_ touches: Set<UITouch>, with event: UIEvent?) {
        self.customDelegate?.touchesEnded(touches, with: event)
    }
    

    /*
    // Only override draw() if you perform custom drawing.
    // An empty implementation adversely affects performance during animation.
    override func draw(_ rect: CGRect) {
        // Drawing code
    }
    */

}

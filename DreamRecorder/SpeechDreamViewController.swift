//
//  SpeechDreamViewController.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 8..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class SpeechDreamViewController : UIViewController {
    static func storyboardInstance() -> SpeechDreamViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: Bundle.main)
        return storyboard.instantiateInitialViewController() as? SpeechDreamViewController
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
    }
}

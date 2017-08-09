//
//  AddDraemNavigationController.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 9..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class AddDreamNavigationController : UINavigationController{
    static func storyboardInstance() -> AddDreamNavigationController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AddDreamNavigationController
    }
    
    weak var dreamDataStore : DreamDataStore?
}

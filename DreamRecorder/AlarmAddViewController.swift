//
//  AlarmAddViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 9..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

protocol AlarmOneViewable: NSObjectProtocol {
    var alarm: Alarm? { get set }
}

class AlarmAddViewController: UIViewController, AlarmOneViewable {
    
    var alarm: Alarm?
    
    class func storyboardInstance() -> AlarmAddViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmAddViewController
    }
    
    func leftBarButtonDidTap(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func rightBarButtonDidTap(sender: UIBarButtonItem) {
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        self.alarm = Alarm()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        let leftBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.leftBarButtonDidTap(sender:)))
        self.navigationItem.setLeftBarButton(leftBarButton, animated: true)
        
        let rightBarButton = UIBarButtonItem(title: "Open", style: .done, target: self, action: #selector(self.rightBarButtonDidTap(sender:)))
        self.navigationItem.setRightBarButton(rightBarButton, animated: true)
    }
}

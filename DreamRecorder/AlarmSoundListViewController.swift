//
//  AlarmSoundListViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 16..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class AlarmSoundListViewController: UIViewController {
    var soundNames: [String] = ["Alarm-tone", "Old-alarm-clock-ringing", "Loud-alarm-clock-sound"]
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
}

extension AlarmSoundListViewController: UITableViewDataSource, UITableViewDelegate {
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.soundNames.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.text = soundNames[indexPath.row]
        cell.textLabel?.font = UIFont.title1
        cell.accessoryType = .checkmark
        return cell
    }
}

extension AlarmSoundListViewController {
    class func storyboardInstance() -> AlarmSoundListViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmSoundListViewController
    }
}

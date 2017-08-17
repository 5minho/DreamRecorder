//
//  AlarmSoundListViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 16..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

protocol AlarmSoundListViewControllerDelegate: NSObjectProtocol {
    func alarmSoundListViewController(_ controller: AlarmSoundListViewController, didChangeSoundName: String)
}

class AlarmSoundListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    var soundNames: [String] = ["Default", "Alarm-tone", "Old-alarm-clock-ringing", "Loud-alarm-clock-sound"]
    var alarm: Alarm?
    
    var delegate: AlarmSoundListViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.applyTheme()
        
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
        cell.textLabel?.font = UIFont.title3
        cell.backgroundColor = UIColor.alarmDefaultBackgroundColor
        cell.textLabel?.textColor = UIColor.alarmDarkText
        cell.tintColor = UIColor.alarmSwitchOnTintColor
        if let soundName = self.alarm?.sound {
            cell.accessoryType = (soundName == self.soundNames[indexPath.row]) ? .checkmark : .none
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        for cell in tableView.visibleCells {
            cell.accessoryType = .none
        }
        tableView.cellForRow(at: indexPath)?.accessoryType = .checkmark
        let selectedSoundName = self.soundNames[indexPath.row]
        self.alarm?.sound = selectedSoundName
        self.delegate?.alarmSoundListViewController(self, didChangeSoundName: selectedSoundName)
        self.navigationController?.popViewController(animated: true)
    }
}

extension AlarmSoundListViewController: ThemeAppliable {
    var themeStyle: ThemeStyle {
        return .alarm
    }
    var themeTableView: UITableView? {
        return self.tableView
    }
    var themeNavigationController: UINavigationController? {
        return self.navigationController
    }
}

extension AlarmSoundListViewController {
    class func storyboardInstance() -> AlarmSoundListViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmSoundListViewController
    }
}

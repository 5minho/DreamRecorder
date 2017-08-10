//
//  AlarmListViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 8..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class AlarmListViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    let store = AlarmDataStore()
    
    lazy var alarmAddViewController: AlarmAddViewController? = {
        return AlarmAddViewController.storyboardInstance()
    }()
    
    func leftBarButtonDidTap(sender: UIBarButtonItem) {
        self.tableView.setEditing(!self.tableView.isEditing, animated: true)
    }
    
    func rightBarButtonDidTap(sender: UIBarButtonItem) {
        guard let alarmAddViewController = self.alarmAddViewController else { return }
        let navigationController = UINavigationController(rootViewController: alarmAddViewController)
        
        alarmAddViewController.delegate = self
        alarmAddViewController.alarm = Alarm()
        
        self.present(navigationController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.estimatedRowHeight = 90
        self.tableView.tableFooterView = UIView(frame: .zero)
        
        let leftBarButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(self.leftBarButtonDidTap(sender:)))
        self.navigationItem.setLeftBarButton(leftBarButton, animated: true)
        
        let rightBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.rightBarButtonDidTap(sender:)))
        
        self.navigationItem.setRightBarButton(rightBarButton, animated: true)
        
        self.store.createTable()
        self.store.reloadAlarms()
    }
}

extension AlarmListViewController: UITableViewDelegate, UITableViewDataSource {
    
    // DataSource.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.store.alarms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        if let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmListCell",
                                                    for: indexPath) as? AlarmListCell {
            cell.timeLabel.text = DateParser().time(from: self.store.alarms[indexPath.row].date)
            cell.nameLabel.text = self.store.alarms[indexPath.row].name
            cell.weekdayButton.setSelection(options: self.store.alarms[indexPath.row].weekday)
//            cell.weekdayButton.setButtonsEnabled(to: false)
            return cell
        } else {
            return AlarmListCell(style: .default, reuseIdentifier: "AlarmListCell")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let alarmScheduler = AlarmScheduler()
        alarmScheduler.getNotifications()
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        if editingStyle == .delete {
            let deletingAlarm = self.store.alarms.remove(at: indexPath.row)
            self.store.deleteAlarm(alarm: deletingAlarm)
            let deletingRow = IndexPath(row: indexPath.row, section: 0)
            tableView.deleteRows(at: [deletingRow], with: .automatic)
        }
    }
}

extension AlarmListViewController: AlarmAddViewControllerDelegate {
    func alarmAddViewController(_: AlarmAddViewController, didSaveNewAlarm alarm: Alarm) {
        self.store.alarms.append(alarm)
        self.store.insertAlarm(alarm: alarm)
        self.tableView.reloadData()
    }
}

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
    
    func leftBarButtonDidTap(sender: UIBarButtonItem) {
        self.tableView.setEditing(!self.tableView.isEditing, animated: true)
    }
    
    func rightBarButtonDidTap(sender: UIBarButtonItem) {
        let alarm = Alarm(id: UUID().uuidString, name: "NewAlarm", date: Date().addingTimeInterval(60), weekday: .tue, isActive: true, isSnooze: true)
        self.store.insertAlarm(alarm: alarm)
        self.store.reloadAlarms()
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        let leftBarButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(self.leftBarButtonDidTap(sender:)))
        self.navigationItem.setLeftBarButton(leftBarButton, animated: true)
        
        let rightBarButton = UIBarButtonItem(title: "+", style: .done, target: self, action: #selector(self.rightBarButtonDidTap(sender:)))
        self.navigationItem.setRightBarButton(rightBarButton, animated: true)
        
        self.store.createTable()
        self.store.reloadAlarms()
        let alarmScheduler = AlarmScheduler()
        let alarm = Alarm(id: "hello", name: "NewAlarm", date: Date().addingTimeInterval(60), weekday: .weekdays, isActive: true, isSnooze: true)
        alarmScheduler.addNotification(with: alarm)
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
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        cell.textLabel?.text = self.store.alarms[indexPath.row].name
        return cell
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

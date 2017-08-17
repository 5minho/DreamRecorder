//
//  AlarmListViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 8..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class AlarmListViewController: UIViewController, ThemeAppliable {
    
    // AlarmThemeAppliable
    var themeStyle: ThemeStyle = .alarm
    var themeTableView: UITableView? {
        return self.tableView
    }
    var themeNavigationController: UINavigationController? {
        return self.navigationController
    }
    
    // IBOutlet Subviews.
    @IBOutlet weak var tableView: UITableView!
    
    // Properties.
    lazy var store = AlarmDataStore.shared
    
    // CellExpandableAnimator temporary views.
    var selectedCell: UITableViewCell?
    var selectedCellLabel: UILabel?
    
    // IBActions.
    func leftBarButtonDidTap(sender: UIBarButtonItem) {
        self.tableView.setEditing(!self.tableView.isEditing, animated: true)
    }
    
    func rightBarButtonDidTap(sender: UIBarButtonItem) {
        guard let alarmAddViewController = AlarmAddViewController.storyboardInstance() else { return }
        let navigationController = UINavigationController(rootViewController: alarmAddViewController)
        
        alarmAddViewController.delegate = self
        alarmAddViewController.alarm = Alarm()
        
        self.present(navigationController, animated: true, completion: nil)
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.applyTheme()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.estimatedRowHeight = 90
        self.tableView.allowsSelectionDuringEditing = true
        
        let leftBarButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(self.leftBarButtonDidTap(sender:)))
        self.navigationItem.setLeftBarButton(leftBarButton, animated: true)
        
        let rightBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.rightBarButtonDidTap(sender:)))
        self.navigationItem.setRightBarButton(rightBarButton, animated: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.didChnagedAlarms), name: Notification.Name.AlarmDateStoreDidSyncAlarmAndNotification, object: nil)
        
        self.store.reloadAlarms()
    }
    
    func didChnagedAlarms(){
        DispatchQueue.main.async {
            self.tableView.reloadData()
        }

    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.tableView.setEditing(false, animated: true)
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
            cell.activeSwitch.isOn = self.store.alarms[indexPath.row].isActive
            cell.activeSwitch.tag = indexPath.row
            cell.delegate = self
//            cell.weekdayButton.setButtonsEnabled(to: false)
            return cell
        } else {
            return AlarmListCell(style: .default, reuseIdentifier: "AlarmListCell")
        }
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if self.tableView.isEditing {
            guard let alarmEditViewController = AlarmEditViewController.storyboardInstance() else { return }
            alarmEditViewController.alarm = self.store.alarms[indexPath.row]
            alarmEditViewController.delegate = self
            let navigationController = UINavigationController(rootViewController: alarmEditViewController)
            self.present(navigationController, animated: true, completion: nil)
        } else {
            guard let cell = tableView.cellForRow(at: indexPath) as? AlarmListCell else { return }
            self.selectedCell = cell
            self.selectedCellLabel = cell.timeLabel
            
            let selectedAlarm = self.store.alarms[indexPath.row]
            
            if selectedAlarm.isActive == false {
                let alertController = UIAlertController(title: "Alarm", message: "알람을 활성화 시키겠습니까?", preferredStyle: .alert)
                let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: { (action) in
                    alertController.dismiss(animated: true, completion: nil)
                })
                let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    alertController.dismiss(animated: true, completion: nil)
                    guard let alarmPlayViewController = AlarmPlayViewController.storyboardInstance() else { return }
                    alarmPlayViewController.presentingDelegate = self
                    alarmPlayViewController.playingAlarm = selectedAlarm
                    self.present(alarmPlayViewController, animated: true, completion: nil)
                    
                })
                alertController.addAction(cancelAction)
                alertController.addAction(okAction)
                self.present(alertController, animated: true, completion: nil)
            } else {
                guard let alarmPlayViewController = AlarmPlayViewController.storyboardInstance() else { return }
                alarmPlayViewController.presentingDelegate = self
                alarmPlayViewController.playingAlarm = selectedAlarm
                self.present(alarmPlayViewController, animated: true, completion: nil)
            }
            
            
        }
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
extension AlarmListViewController: AlarmListCellDelegate{
    func alarmListCell(cell : AlarmListCell, activeSwitchValueChanged sender: UISwitch) {
        guard sender.tag < self.store.alarms.count else { return }
        
        let updatedAlarm = self.store.alarms[sender.tag]
        if sender.isOn {
            self.store.scheduler.addNotification(with: updatedAlarm)
        } else {
            self.store.scheduler.deleteNotification(with: updatedAlarm)
        }
    }
}
extension AlarmListViewController: AlarmAddViewControllerDelegate, AlarmEditViewControllerDelegate {
    // Add Controller Delegate.
    func alarmAddViewController(_: AlarmAddViewController, didSaveNewAlarm alarm: Alarm) {
        self.store.alarms.append(alarm)
        self.store.insertAlarm(alarm: alarm)
        
        self.tableView.reloadSections(IndexSet(integersIn: 0...0), with: .automatic)
    }
    // Edit Controller Delegate.
    func alarmEditViewController(_ controller: AlarmEditViewController, didSaveEditedAlarm alarm: Alarm) {
        self.store.updateAlarm(alarm: alarm)
        
        guard let row = self.store.alarms.index(of: alarm) else { return }
        let indexPath = IndexPath(row: row, section: 0)
        self.tableView.reloadRows(at: [indexPath], with: .automatic)
    }
}

extension AlarmListViewController: CellExpandAnimatorPresentingDelegate {
    var presentingView: UIView {
        return self.selectedCell ?? self.view
    }
    var presentingLabel: UILabel {
        return self.selectedCellLabel ?? UILabel()
    }
}

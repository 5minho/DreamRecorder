//
//  AlarmListViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 8..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class AlarmListViewController: UIViewController {

    // MARK: Properties.
    // Subviews.
    @IBOutlet weak var tableView: UITableView!
    
    // Internal.
    lazy var store = AlarmDataStore.shared
    
    // Private.
    fileprivate var shouldReloadTable: Bool = true  // default is true. it will set false to block reload table from AlarmDataStoreDidChange notification.
    
    fileprivate var selectedCell: AlarmListCell?  // Capture temporary selected cell and label for custom transitioning.
    fileprivate var selectedCellLabel: UILabel?
    
    // MARK: Actions.
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
    
    // MARK: View Cycle.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.applyThemeIfViewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.estimatedRowHeight = 90
        self.tableView.allowsSelectionDuringEditing = true
        
        let leftBarButton = UIBarButtonItem(title: "Edit", style: .plain, target: self, action: #selector(self.leftBarButtonDidTap(sender:)))
        self.navigationItem.setLeftBarButton(leftBarButton, animated: true)
        
        let rightBarButton = UIBarButtonItem(barButtonSystemItem: .add, target: self, action: #selector(self.rightBarButtonDidTap(sender:)))
        self.navigationItem.setRightBarButton(rightBarButton, animated: true)
        
        NotificationCenter.default.addObserver(self, selector: #selector(self.handleAlarmDataStoreDidChange), name: Notification.Name.AlarmDataStoreDidChange, object: nil)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.applyThemeIfViewWillAppear()
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.tableView.setEditing(false, animated: true)
    }
    
    // MARK: Notification Handler.
    func handleAlarmDataStoreDidChange(sender: Notification){
        if shouldReloadTable {
            OperationQueue.main.addOperation {
                self.tableView.reloadSections(IndexSet(integer: IndexSet.Element.allZeros), with: .automatic)
            }
        }
        self.shouldReloadTable = true
    }
}

extension AlarmListViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: TableView DataSource.
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
    
    // MARK: TableView Delegate.
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
                
                let alertController = UIAlertController(title: NSLocalizedString("Alarm", comment: ""),
                                                        message: NSLocalizedString("알람을 먼저 활성화 하십시오.", comment: ""),
                                                        preferredStyle: .alert)
                let okAction = UIAlertAction(title: "OK", style: .default, handler: { (action) in
                    alertController.dismiss(animated: true, completion: nil)
                })
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
            self.shouldReloadTable = false
            
            let deletingAlarm = self.store.alarms[indexPath.row]
            self.store.deleteAlarm(alarm: deletingAlarm)
            
            // Replace reload table with deleting rows if alarm deleted.
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
}
extension AlarmListViewController: AlarmListCellDelegate {
    // MARK: AlarmListCell Delegate.
    func alarmListCell(cell : AlarmListCell, activeSwitchValueChanged sender: UISwitch) {
        guard sender.tag < self.store.alarms.count else { return }
        let updatingAlarm = self.store.alarms[sender.tag]
        updatingAlarm.isActive = sender.isOn
        self.store.updateAlarm(alarm: updatingAlarm)
    }
}

extension AlarmListViewController: AlarmAddViewControllerDelegate, AlarmEditViewControllerDelegate {
    // MARK: AlarmAddViewController Delegate.
    func alarmAddViewController(_: AlarmAddViewController, didSaveNewAlarm alarm: Alarm) {
        self.shouldReloadTable = false
        
        alarm.date = alarm.date.removingSeconds()
        self.store.insertAlarm(alarm: alarm)
        
        // Replace reload table with inserting rows if alarm added.
        guard let index = self.store.alarms.index(of: alarm) else { return }
        let newIndexPath = IndexPath(row: index, section: 0)
        self.tableView.insertRows(at: [newIndexPath], with: .automatic)
        
    }
    
    // MARK: AlarmEditViewController Delegate.
    func alarmEditViewController(_ controller: AlarmEditViewController, didSaveEditedAlarm alarm: Alarm) {
        self.shouldReloadTable = false
        
        alarm.date = alarm.date.removingSeconds()
        if alarm.isActive == false {
            let alertController = UIAlertController(title: NSLocalizedString("Alarm", comment: ""),
                                                    message: NSLocalizedString("수정된 알람을 활성화 시키겠습니까?", comment: ""),
                                                    preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK", style: .default) { (action) in
                alarm.isActive = true
                self.store.updateAlarm(alarm: alarm)
                
                // Replace reload table with reloading rows if alarm updated.
                guard let index = self.store.alarms.index(of: alarm) else { return }
                let editedIndexPath = IndexPath(row: index, section: 0)
                self.tableView.reloadRows(at: [editedIndexPath], with: .automatic)
            }
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in
                self.store.updateAlarm(alarm: alarm)
                
                // Replace reload table with reloading rows if alarm updated.
                guard let index = self.store.alarms.index(of: alarm) else { return }
                let editedIndexPath = IndexPath(row: index, section: 0)
                self.tableView.reloadRows(at: [editedIndexPath], with: .automatic)
            }
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        } else {
            self.store.updateAlarm(alarm: alarm)
            
            // Replace reload table with reloading rows if alarm updated.
            guard let index = self.store.alarms.index(of: alarm) else { return }
            let editedIndexPath = IndexPath(row: index, section: 0)
            self.tableView.reloadRows(at: [editedIndexPath], with: .automatic)
        }
    }
}

extension AlarmListViewController: ThemeAppliable {
    // MARK: ThemeAppliable.
    var themeStyle: ThemeStyle {
        return .alarm
    }
    var themeTableView: UITableView? {
        return self.tableView
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

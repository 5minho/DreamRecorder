//
//  AlarmAddViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 9..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

protocol AlarmAddViewControllerDelegate: NSObjectProtocol {
    func alarmAddViewController(_: AlarmAddViewController, didSaveNewAlarm alarm: Alarm)
}

class AlarmAddViewController: UIViewController {
    
    // MARK: Properties.
    // SubViews.
    @IBOutlet weak var tableView: UITableView!
    var datePicker: UIDatePicker!
    
    // Model and Delegate.
    var alarm: Alarm?
    weak var delegate: AlarmAddViewControllerDelegate?
    
    // MARK: Functions.
    // Actions.
    func leftBarButtonDidTap(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func rightBarButtonDidTap(sender: UIBarButtonItem) {
        guard let newAlarm = self.alarm else { return }
        newAlarm.isActive = true
        self.dismiss(animated: true, completion: {
            [unowned self] in
            self.delegate?.alarmAddViewController(self, didSaveNewAlarm: newAlarm)
        })
    }
    
    func datePickerDidChangeValue(sender: UIDatePicker) {
        guard let newAlarm = self.alarm else { return }
        newAlarm.date = sender.date
    }
    
    // MARK: View LifeCycle.
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        // Reset Views Property.
        // This is because ListViewController is reuse this controller for adding alarm repeatly.
        guard let newAlarm = self.alarm else { return }
        self.datePicker.date = newAlarm.date
        self.tableView.reloadData()
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.applyTheme()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.tableFooterView = UIView(frame: .zero)
        
        self.datePicker = UIDatePicker()
        self.datePicker.datePickerMode = .time
        self.datePicker.addTarget(self, action: #selector(self.datePickerDidChangeValue(sender:)), for: .valueChanged)
        self.tableView.tableHeaderView = self.datePicker
        
        let leftBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.leftBarButtonDidTap(sender:)))
        self.navigationItem.setLeftBarButton(leftBarButton, animated: true)
        
        let rightBarButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(self.rightBarButtonDidTap(sender:)))
        self.navigationItem.setRightBarButton(rightBarButton, animated: true)
    }
}

// MARK: TableView DataSourcem Delegate.
extension AlarmAddViewController: UITableViewDataSource, UITableViewDelegate {
    // DataSource.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmDetailCell", for: indexPath) as? AlarmDetailCell else { return UITableViewCell() }
        guard let style = AlarmDetailCellStyle(rawValue: indexPath.row) else { return UITableViewCell() }
        guard let newAlarm = self.alarm else { return UITableViewCell() }
        
        cell.cellStyle = style
        cell.delegate = self
        
        if indexPath.row == AlarmDetailCellStyle.repeat.rawValue {
            if let weekdayButtonsAccessoryView = cell.weekdayButtonAccessoryView {
                weekdayButtonsAccessoryView.setSelection(options: newAlarm.weekday)
            }
        } else if indexPath.row == AlarmDetailCellStyle.label.rawValue {
            cell.detailTextLabel?.text = newAlarm.name
        } else if indexPath.row == AlarmDetailCellStyle.sound.rawValue {
            cell.detailTextLabel?.text = newAlarm.sound
        } else if indexPath.row == AlarmDetailCellStyle.snooze.rawValue {
            if let switchAccessoryView = cell.switchAccessoryView {
                switchAccessoryView.isOn = newAlarm.isSnooze
            }
        }
        return cell

    }
    
    // Delegate.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case AlarmDetailCellStyle.label.rawValue:
            let alertController = UIAlertController(title: "Title Label", message: nil, preferredStyle: .alert)
            alertController.addTextField(configurationHandler: {
                [unowned self] (textField) in
                textField.text = self.alarm?.name
            })
            let doneAction = UIAlertAction(title: "Done", style: .default, handler: {
                [unowned self, unowned tableView] (action) in
                guard let editingAlarm = self.alarm else { return }
                guard let text = alertController.textFields?.first?.text else { return }
                tableView.cellForRow(at: indexPath)?.detailTextLabel?.text = text
                editingAlarm.name = text
            })
            
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            alertController.addAction(doneAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        case AlarmDetailCellStyle.sound.rawValue:
            guard let alarmSoundListViewController = AlarmSoundListViewController.storyboardInstance() else { return }
            alarmSoundListViewController.delegate = self
            alarmSoundListViewController.alarm = self.alarm
            self.navigationController?.pushViewController(alarmSoundListViewController, animated: true)
        default:
            // Another cell have AccessoryView Action that is called by cell delegate.
            break
        }
    }
}

// MARK: AccessoryView Actions.
extension AlarmAddViewController: AlarmDetailCellDelegate {
    func alarmDetailCell(_: AlarmDetailCell, repeatButtonDidTouchUp button: UIButton, at index: Int) {
        guard let editingAlarm = self.alarm else { return }
        let weekday = WeekdayOptions(rawValue: 1 << index)
        if button.isSelected {
            editingAlarm.weekday.insert(weekday)
        } else {
            editingAlarm.weekday.remove(weekday)
        }
    }

    func alarmDetailCell(_: AlarmDetailCell, snoozeSwitchValueChanged sender: UISwitch) {
        guard let editingAlarm = self.alarm else { return }
        editingAlarm.isSnooze = sender.isOn
    }
}

extension AlarmAddViewController: AlarmSoundListViewControllerDelegate {
    func alarmSoundListViewController(_ controller: AlarmSoundListViewController, didChangeSoundName: String) {
        let soundCellIndexPath = IndexPath(row: AlarmDetailCellStyle.sound.rawValue, section: 0)
        self.tableView.reloadRows(at: [soundCellIndexPath], with: .automatic)
    }
}

extension AlarmAddViewController: ThemeAppliable {
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

extension AlarmAddViewController {
    class func storyboardInstance() -> AlarmAddViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmAddViewController
    }
}

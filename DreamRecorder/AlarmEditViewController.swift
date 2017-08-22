//
//  AlarmEditViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 11..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

protocol AlarmEditViewControllerDelegate: NSObjectProtocol {
    func alarmEditViewController(_ controller: AlarmEditViewController, didSaveEditedAlarm alarm: Alarm)
}

class AlarmEditViewController: UIViewController {
    
    // MARK: Properties.
    // SubViews.
    @IBOutlet weak var tableView: UITableView!
    var datePicker: UIDatePicker!
    
    // Internal.
    var alarm: Alarm? {
        didSet {
            self.editingAlarm = self.alarm?.copy() as? Alarm
        }
    }
    var editingAlarm: Alarm?
    weak var delegate: AlarmEditViewControllerDelegate?
    
    // MARK: Actions.
    func leftBarButtonDidTap(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func rightBarButtonDidTap(sender: UIBarButtonItem) {
        guard let editedAlarm = self.editingAlarm else { return }
        guard let originalAlarm = self.alarm else { return }
        
        originalAlarm.date = editedAlarm.date
        originalAlarm.name = editedAlarm.name
        originalAlarm.weekday = editedAlarm.weekday
        originalAlarm.sound = editedAlarm.sound
        originalAlarm.isSnooze = editedAlarm.isSnooze
        self.dismiss(animated: true, completion: {
            [unowned self] in
            self.delegate?.alarmEditViewController(self, didSaveEditedAlarm: originalAlarm)
        })
    }
    
    func datePickerValueDidChange(sender: UIDatePicker) {
        guard let editingAlarm = self.editingAlarm else { return }
        editingAlarm.date = sender.date
    }
    
    // MARK: View Cycle.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.applyThemeIfViewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView(frame: .zero)
        
        self.datePicker = UIDatePicker()
        self.datePicker.date = self.alarm?.date ?? Date()
        self.datePicker.datePickerMode = .time
        self.datePicker.addTarget(self, action: #selector(self.datePickerValueDidChange(sender:)), for: .valueChanged)
        self.tableView.tableHeaderView = self.datePicker
        
        let leftBarButton = UIBarButtonItem(title: "Cancel".localized, style: .plain, target: self, action: #selector(self.leftBarButtonDidTap(sender:)))
        self.navigationItem.setLeftBarButton(leftBarButton, animated: true)
        
        let rightBarButton = UIBarButtonItem(title: "Save".localized, style: .done, target: self, action: #selector(self.rightBarButtonDidTap(sender:)))
        self.navigationItem.setRightBarButton(rightBarButton, animated: true)
    }
}

// MARK: TableView DataSourcem Delegate.
extension AlarmEditViewController: UITableViewDataSource, UITableViewDelegate {
    // TableView DataSource.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmDetailCell", for: indexPath) as? AlarmDetailCell else { return UITableViewCell() }
        guard let style = AlarmDetailCellStyle(rawValue: indexPath.row) else { return UITableViewCell() }
        guard let editingAlarm = self.editingAlarm else { return UITableViewCell() }
        
        cell.cellStyle = style
        cell.delegate = self
        
        switch indexPath.row {
        case AlarmDetailCellStyle.repeat.rawValue:
            guard let weekdayButtonsAccessoryView = cell.weekdayButtonAccessoryView else { break }
            weekdayButtonsAccessoryView.setSelection(options: editingAlarm.weekday)
            
        case AlarmDetailCellStyle.label.rawValue:
            cell.detailTextLabel?.text = editingAlarm.name
            
        case AlarmDetailCellStyle.sound.rawValue:
            cell.detailTextLabel?.text = editingAlarm.sound.soundTitle
            
        case AlarmDetailCellStyle.snooze.rawValue:
            guard let switchAccessoryView = cell.switchAccessoryView else { break }
            switchAccessoryView.isOn = editingAlarm.isSnooze
            
        default:
            break
        }
        return cell
    }
    
    // MARK: TableView Delegate.
    // @discussion      Handle only label, sound cell.
    //                  Other cells have accessoryView action that is called by cell delegate.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.row {
        case AlarmDetailCellStyle.label.rawValue:
            let alertController = UIAlertController(title: "Alarm Label".localized, message: nil, preferredStyle: .alert)
            alertController.addTextField(configurationHandler: {
                [unowned self] (textField) in
                textField.text = self.editingAlarm?.name
            })
            let cancelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
            let doneAction = UIAlertAction(title: "Done", style: .default, handler: {
                [unowned self, unowned tableView] (action) in
                guard let text = alertController.textFields?.first?.text else { return }
                self.editingAlarm?.name = text
                tableView.cellForRow(at: indexPath)?.detailTextLabel?.text = text
            })
            alertController.addAction(doneAction)
            alertController.addAction(cancelAction)
            self.present(alertController, animated: true, completion: nil)
        case AlarmDetailCellStyle.sound.rawValue:
            guard let alarmSoundListViewController = AlarmSoundListViewController.storyboardInstance() else { return }
            alarmSoundListViewController.delegate = self
            alarmSoundListViewController.alarm = self.editingAlarm
            self.navigationController?.pushViewController(alarmSoundListViewController, animated: true)
        default:
            // Another cell have AccessoryView Action that is called by cell delegate.
            break
        }
    }
}

// MARK: AccessoryView Actions.
extension AlarmEditViewController: AlarmDetailCellDelegate {
    // MARK: AlarmDetailCellDelegate
    func alarmDetailCell(_: AlarmDetailCell, repeatButtonDidTouchUp button: UIButton, at index: Int) {
        let weekday = WeekdayOptions(rawValue: 1 << index)
        
        if button.isSelected {
            self.editingAlarm?.weekday.insert(weekday)
        } else {
            self.editingAlarm?.weekday.remove(weekday)
        }
    }
    
    func alarmDetailCell(_: AlarmDetailCell, snoozeSwitchValueChanged sender: UISwitch) {
        self.editingAlarm?.isSnooze = sender.isOn
    }
}

extension AlarmEditViewController: AlarmSoundListViewControllerDelegate {
    // MARK: AlarmSoundListViewController Delegate.
    func alarmSoundListViewController(_ controller: AlarmSoundListViewController, didChangeSoundName: String) {
        let soundCellIndexPath = IndexPath(row: AlarmDetailCellStyle.sound.rawValue, section: 0)
        self.tableView.reloadRows(at: [soundCellIndexPath], with: .automatic)
    }
}

extension AlarmEditViewController: ThemeAppliable {
    // MARK: ThemeAppliable.
    var themeStyle: ThemeStyle {
        return .alarm
    }
    var themeTableView: UITableView? {
        return self.tableView
    }
}

extension AlarmEditViewController {
    // MARK: Storyboard Instance.
    class func storyboardInstance() -> AlarmEditViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmEditViewController
    }
}

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
    private var datePicker: UIDatePicker!
    
    // Internal.
    var alarm: Alarm?
    weak var delegate: AlarmAddViewControllerDelegate?
    
    // MARK: Actions.
    func leftBarButtonDidTap(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func rightBarButtonDidTap(sender: UIBarButtonItem) {
        
        guard let newAlarm = self.alarm else { return print(#function) }
        newAlarm.isActive = true
        
        self.dismiss(animated: true, completion: {
            self.delegate?.alarmAddViewController(self, didSaveNewAlarm: newAlarm)
        })
        
        
    }
    
    func datePickerValueDidChange(sender: UIDatePicker) {
        guard let newAlarm = self.alarm else { return }
        newAlarm.date = sender.date
    }
    
    // MARK: View Cycle.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.applyThemeIfViewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.tableFooterView = UIView(frame: .zero)
        
        self.datePicker = UIDatePicker()
        self.datePicker.datePickerMode = .time
        self.datePicker.addTarget(self, action: #selector(self.datePickerValueDidChange(sender:)), for: .valueChanged)
        self.tableView.tableHeaderView = self.datePicker
        
        let leftBarButton = UIBarButtonItem(title: "Cancel", style: .plain, target: self, action: #selector(self.leftBarButtonDidTap(sender:)))
        self.navigationItem.setLeftBarButton(leftBarButton, animated: true)
        
        let rightBarButton = UIBarButtonItem(title: "Save", style: .done, target: self, action: #selector(self.rightBarButtonDidTap(sender:)))
        self.navigationItem.setRightBarButton(rightBarButton, animated: true)
        
        self.title = "Add Alarm".localized
    }
}


extension AlarmAddViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: TableView DataSource.
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
        
        switch indexPath.row {
        case AlarmDetailCellStyle.repeat.rawValue:
            guard let weekdayButtonsAccessoryView = cell.weekdayButtonAccessoryView else { break }
            weekdayButtonsAccessoryView.setSelection(options: newAlarm.weekday)
            
        case AlarmDetailCellStyle.label.rawValue:
            cell.detailTextLabel?.text = newAlarm.name
            
        case AlarmDetailCellStyle.sound.rawValue:
            cell.detailTextLabel?.text = newAlarm.sound.soundTitle
            
        case AlarmDetailCellStyle.snooze.rawValue:
            guard let switchAccessoryView = cell.switchAccessoryView else { break }
            switchAccessoryView.isOn = newAlarm.isSnooze
            
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
            let alertController = UIAlertController(title: NSLocalizedString("Title Label", comment: ""), message: nil, preferredStyle: .alert)
            
            alertController.addTextField(configurationHandler: {
                [unowned self] (textField) in
                textField.text = self.alarm?.name
            })
            
            let cancelAction = UIAlertAction(title: NSLocalizedString("Cancel", comment: ""), style: .cancel, handler: nil)
            let doneAction = UIAlertAction(title: NSLocalizedString("Done", comment: ""), style: .default, handler: {
                [unowned self, unowned tableView] (action) in
                
                guard let newAlarm = self.alarm else { return }
                guard let text = alertController.textFields?.first?.text else { return }
                
                let labelCell = tableView.cellForRow(at: indexPath)
                labelCell?.detailTextLabel?.text = text
                newAlarm.name = text
            })
            
            alertController.addAction(cancelAction)
            alertController.addAction(doneAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        case AlarmDetailCellStyle.sound.rawValue:
            guard let alarmSoundListViewController = AlarmSoundListViewController.storyboardInstance() else { return }
            alarmSoundListViewController.delegate = self
            alarmSoundListViewController.alarm = self.alarm
            self.navigationController?.pushViewController(alarmSoundListViewController, animated: true)
            
        default:
            break
        }
    }
}


extension AlarmAddViewController: AlarmDetailCellDelegate {
    // MARK: AlarmDetailCell Delegate.
    func alarmDetailCell(_: AlarmDetailCell, repeatButtonDidTouchUp button: UIButton, at index: Int) {
        let weekday = WeekdayOptions(rawValue: 1 << index)
        
        if button.isSelected {
            self.alarm?.weekday.insert(weekday)
        } else {
            self.alarm?.weekday.remove(weekday)
        }
    }

    func alarmDetailCell(_: AlarmDetailCell, snoozeSwitchValueChanged sender: UISwitch) {
        self.alarm?.isSnooze = sender.isOn
    }
}

extension AlarmAddViewController: AlarmSoundListViewControllerDelegate {
    // MARK: AlarmSoundListViewController Delegate.
    func alarmSoundListViewController(_ controller: AlarmSoundListViewController, didChangeSoundName: String) {
        let soundCellIndexPath = IndexPath(row: AlarmDetailCellStyle.sound.rawValue, section: 0)
        self.tableView.reloadRows(at: [soundCellIndexPath], with: .automatic)
    }
}

extension AlarmAddViewController: ThemeAppliable {
    // MARK: ThemeAppliable
    var themeStyle: ThemeStyle {
        return .alarm
    }
    var themeTableView: UITableView? {
        return self.tableView
    }
}

extension AlarmAddViewController {
    class func storyboardInstance() -> AlarmAddViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmAddViewController
    }
}

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
    
    // MARK: - Properties.
    // SubViews.
    @IBOutlet weak var tableView: UITableView!
    private var datePicker: UIDatePicker!
    
    // Internal.
    /// DatePicker나 Cell 액션에 의해 Alarm객체의 프로퍼티가 바로 변경되는데 이때 취소되었을 때 같은 참조값을 가지고 있던
    /// alarm(AlarmListViewController에서 참고하고 있는)은 변경되지 않게 하기 위해 alarm객체를 복사하여 editingAlarm로 가지고 있는다.
    /// alarm은 RightBarButton(Done Button)이 눌리기 전까지는 더이상 참조하지 않는다.
    var alarm: Alarm? {
        didSet {
            self.editingAlarm = self.alarm?.copy() as? Alarm
        }
    }
    var editingAlarm: Alarm?
    weak var delegate: AlarmEditViewControllerDelegate?
    
    // MARK: - Actions.
    // NavigationItem.
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
            self.delegate?.alarmEditViewController(self, didSaveEditedAlarm: originalAlarm)
        })
    }
    
    func datePickerValueDidChange(sender: UIDatePicker) {
        guard let editingAlarm = self.editingAlarm else { return }
        editingAlarm.date = sender.date
    }
    
    // MARK: - View Cycle.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.applyThemeIfViewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 44
        
        self.datePicker = UIDatePicker()
        self.datePicker.date = self.alarm?.date ?? Date()
        self.datePicker.datePickerMode = .time
        self.datePicker.setValue(UIColor.dreamTextColor1, forKey: "textColor")
        self.datePicker.addTarget(self,
                                  action: #selector(self.datePickerValueDidChange(sender:)),
                                  for: .valueChanged)
        self.tableView.tableHeaderView = self.datePicker
        
        let leftBarButton = UIBarButtonItem(title: BarButtonText.cancel,
                                            style: .plain,
                                            target: self,
                                            action: #selector(self.leftBarButtonDidTap(sender:)))
        let rightBarButton = UIBarButtonItem(title: BarButtonText.save,
                                             style: .done,
                                             target: self,
                                             action: #selector(self.rightBarButtonDidTap(sender:)))
        
        self.navigationItem.setLeftBarButton(leftBarButton, animated: true)
        self.navigationItem.setRightBarButton(rightBarButton, animated: true)
        
        self.title = NavigationTitle.editAlarm
    }
}

// MARK: - TableView DataSourcem Delegate.
extension AlarmEditViewController: UITableViewDataSource, UITableViewDelegate {
    // TableView DataSource.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.alarmDetailCell, for: indexPath) as? AlarmDetailCell else { return UITableViewCell() }
        guard let cellStyle = AlarmDetailCellStyle(rawValue: indexPath.row) else { return UITableViewCell() }
        guard let editingAlarm = self.editingAlarm else { return UITableViewCell() }
        
        cell.cellStyle = cellStyle
        cell.delegate = self
        
        cell.textLabel?.textColor = .dreamTextColor1
        cell.detailTextLabel?.textColor = .dreamTextColor2
        
        switch cellStyle {
        case .repeat:
            guard let weekdayButtonsAccessoryView = cell.weekdayButtonAccessoryView else { break }
            weekdayButtonsAccessoryView.setSelection(options: editingAlarm.weekday)
            
        case .label:
            cell.detailTextLabel?.text = editingAlarm.name
            
        case .sound:
            cell.detailTextLabel?.text = editingAlarm.sound.soundTitle
            
        case .snooze:
            guard let switchAccessoryView = cell.switchAccessoryView else { break }
            switchAccessoryView.isOn = editingAlarm.isSnooze
        }
        return cell
    }
    
    // MARK: - TableView Delegate.
    /// didSelectRow에서는 오직 Label과 Sound 셀만 처리한다.
    /// 나머지 다른 셀(Repeat, Snooze)는 AccessoryView의 Action에 대응해야한다.
    /// AccessoryView의 Action은 커스텀 셀인 AlarmDetailCell의 Delegate에 정의되어 있다.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        guard let cellStyle = AlarmDetailCellStyle(rawValue: indexPath.row) else { return }
        
        switch cellStyle {
        case .label:
            
            let alertController = UIAlertController(title: AlartText.alarmName, message: nil, preferredStyle: .alert)
            alertController.addTextField(configurationHandler: {
                [unowned self] (textField) in
                textField.text = self.editingAlarm?.name
                textField.clearButtonMode = .always
            })
            
            let cancelAction = UIAlertAction(title: AlartText.cancel, style: .cancel, handler: nil)
            let doneAction = UIAlertAction(title: AlartText.done.localized, style: .default, handler: {
                [unowned self, unowned tableView] (action) in
                
                guard let text = alertController.textFields?.first?.text else { return }
                
                let labelCell = tableView.cellForRow(at: indexPath)
                labelCell?.detailTextLabel?.text = text
                
                self.editingAlarm?.name = text
            })
            
            alertController.addAction(doneAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        case .sound:
            
            guard let alarmSoundListViewController = AlarmSoundListViewController.storyboardInstance() else { return }
            
            alarmSoundListViewController.delegate = self
            alarmSoundListViewController.alarm = self.editingAlarm
            
            self.navigationController?.pushViewController(alarmSoundListViewController, animated: true)
        
        default:
            /// Repeat과 Snooze셀은 셀을 눌럿을 때는 아무것도 하지 않는다.
            /// 그들은 오직 AccessoryView의 Action을 통해서 alarm의 프로퍼티를 변경한다.
            break
        }
    }
}

// MARK: - AccessoryView Actions.
extension AlarmEditViewController: AlarmDetailCellDelegate {
    // MARK: - AlarmDetailCellDelegate
    /// 요일 버튼이 클릭됐을 때 불리는 delegate 메서드.
    /// 각 버튼을 해당 순차적으로 요일을 해당하며 WeekdayOptions를 통해서 alarm객체를 수정한다.
    func alarmDetailCell(_: AlarmDetailCell, repeatButtonDidTouchUp button: UIButton, at index: Int) {
        let weekday = WeekdayOptions(rawValue: 1 << index)
        
        if button.isSelected {
            self.editingAlarm?.weekday.insert(weekday)
        } else {
            self.editingAlarm?.weekday.remove(weekday)
        }
    }
    
    /// 스위치 버튼의 값이 변경됐을 때 불리는 delegate 메서드.
    func alarmDetailCell(_: AlarmDetailCell, snoozeSwitchValueChanged sender: UISwitch) {
        self.editingAlarm?.isSnooze = sender.isOn
    }
}

extension AlarmEditViewController: AlarmSoundListViewControllerDelegate {
    // MARK: - AlarmSoundListViewController Delegate.
    func alarmSoundListViewController(_ controller: AlarmSoundListViewController, didChangeSoundName: String) {
        let soundCellIndexPath = IndexPath(row: AlarmDetailCellStyle.sound.rawValue, section: 0)
        self.tableView.reloadRows(at: [soundCellIndexPath], with: .automatic)
    }
}

extension AlarmEditViewController: ThemeAppliable {
    // MARK: - ThemeAppliable.
    var themeStyle: ThemeStyle {
        return .alarm
    }
    var themeTableView: UITableView? {
        return self.tableView
    }
}

extension AlarmEditViewController {
    // MARK: - Storyboard Instance.
    class func storyboardInstance() -> AlarmEditViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmEditViewController
    }
}

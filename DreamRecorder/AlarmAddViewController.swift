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
    
    // MARK: - Properties.
    // - SubViews.
    @IBOutlet weak var tableView: UITableView!
    private var datePicker: UIDatePicker!
    
    // - Internal.
    var alarm: Alarm?
    weak var delegate: AlarmAddViewControllerDelegate?
    
    // MARK: - Actions.
    // - Navigation Item.
    func leftBarButtonDidTap(sender: UIBarButtonItem) {
        self.dismiss(animated: true, completion: nil)
    }
    
    func rightBarButtonDidTap(sender: UIBarButtonItem) {
        
        guard let newAlarm = self.alarm else { return print(#function) }
        
        self.dismiss(animated: true, completion: {
            self.delegate?.alarmAddViewController(self, didSaveNewAlarm: newAlarm)
        })
    }
    
    // - UIDatePicker.
    func datePickerValueDidChange(sender: UIDatePicker) {
        guard let newAlarm = self.alarm else { return }
        newAlarm.date = sender.date
    }
    
    // MARK: - View Cycle.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.applyThemeIfViewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 44
        
        self.datePicker = UIDatePicker()
        self.datePicker.datePickerMode = .time
        self.datePicker.setValue(UIColor.dreamTextColor1, forKey: "textColor")
        self.datePicker.addTarget(self, action: #selector(self.datePickerValueDidChange(sender:)), for: .valueChanged)
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
        
        self.title = NavigationTitle.addAlarm
    }
}


extension AlarmAddViewController: UITableViewDataSource, UITableViewDelegate {
    // MARK: - TableView DataSource.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return 4
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmDetailCell", for: indexPath) as? AlarmDetailCell else { return UITableViewCell() }
        guard let cellStyle = AlarmDetailCellStyle(rawValue: indexPath.row) else { return UITableViewCell() }
        guard let newAlarm = self.alarm else { return UITableViewCell() }
        
        cell.cellStyle = cellStyle
        cell.delegate = self
        
        cell.textLabel?.textColor = UIColor.dreamTextColor1
        cell.detailTextLabel?.textColor = UIColor.dreamTextColor2
        
        switch cellStyle {
            
        case .repeat:
            guard let weekdayButtonsAccessoryView = cell.weekdayButtonAccessoryView else { break }
            weekdayButtonsAccessoryView.setSelection(options: newAlarm.weekday)
            
        case .label:
            cell.detailTextLabel?.text = newAlarm.name
            
        case .sound:
            cell.detailTextLabel?.text = newAlarm.sound.soundTitle
            
        case .snooze:
            guard let switchAccessoryView = cell.switchAccessoryView else { break }
            switchAccessoryView.isOn = newAlarm.isSnooze
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
                textField.text = self.alarm?.name
                textField.clearButtonMode = .always
            })
            
            let cancelAction = UIAlertAction(title: AlartText.cancel, style: .cancel, handler: nil)
            let doneAction = UIAlertAction(title: AlartText.done, style: .default, handler: {
                [unowned self, unowned tableView] (action) in
                
                guard let text = alertController.textFields?.first?.text else { return }
                
                let labelCell = tableView.cellForRow(at: indexPath)
                labelCell?.detailTextLabel?.text = text
                
                self.alarm?.name = text
            })
            
            alertController.addAction(cancelAction)
            alertController.addAction(doneAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        case .sound:
            
            guard let alarmSoundListViewController = AlarmSoundListViewController.storyboardInstance() else { return }
            
            alarmSoundListViewController.delegate = self
            alarmSoundListViewController.alarm = self.alarm
            
            self.navigationController?.pushViewController(alarmSoundListViewController, animated: true)
            
        default:
            /// Repeat과 Snooze셀은 셀을 눌럿을 때는 아무것도 하지 않는다.
            /// 그들은 오직 AccessoryView의 Action을 통해서 alarm의 프로퍼티를 변경한다.
            break
        }
    }
}


extension AlarmAddViewController: AlarmDetailCellDelegate {
    // MARK: - AlarmDetailCell Delegate.
    
    /// 요일 버튼이 클릭됐을 때 불리는 delegate 메서드.
    /// 각 버튼을 해당 순차적으로 요일을 해당하며 WeekdayOptions를 통해서 alarm객체를 수정한다.
    func alarmDetailCell(_: AlarmDetailCell, repeatButtonDidTouchUp button: UIButton, at index: Int) {
        
        let weekday = WeekdayOptions(rawValue: 1 << index)
        
        if button.isSelected {
            self.alarm?.weekday.insert(weekday)
        } else {
            self.alarm?.weekday.remove(weekday)
        }
    }

    /// 스위치 버튼의 값이 변경됐을 때 불리는 delegate 메서드.
    func alarmDetailCell(_: AlarmDetailCell, snoozeSwitchValueChanged sender: UISwitch) {
        self.alarm?.isSnooze = sender.isOn
    }
}

extension AlarmAddViewController: AlarmSoundListViewControllerDelegate {
    // MARK: - AlarmSoundListViewController Delegate.
    func alarmSoundListViewController(_ controller: AlarmSoundListViewController, didChangeSoundName: String) {
        let soundCellIndexPath = IndexPath(row: AlarmDetailCellStyle.sound.rawValue, section: 0)
        self.tableView.reloadRows(at: [soundCellIndexPath], with: .automatic)
    }
}

extension AlarmAddViewController: ThemeAppliable {
    // MARK: - ThemeAppliable.
    var themeStyle: ThemeStyle {
        return .alarm
    }
    var themeTableView: UITableView? {
        return self.tableView
    }
}

extension AlarmAddViewController {
    // MARK: - StoryboardInstance.
    class func storyboardInstance() -> AlarmAddViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmAddViewController
    }
}

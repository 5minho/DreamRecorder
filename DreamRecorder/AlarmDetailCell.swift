//
//  AlarmDetailTableCell.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 9..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

enum AlarmDetailCellStyle: Int {
    case `repeat` = 0
    case label
    case sound
    case snooze
}

protocol AlarmDetailCellDelegate: NSObjectProtocol {
    func alarmDetailCell(_: AlarmDetailCell, repeatButtonDidTouchUp button: UIButton, at index: Int)
    func alarmDetailCell(_: AlarmDetailCell, snoozeSwitchValueChanged sender: UISwitch)
}

@IBDesignable
class AlarmDetailCell: UITableViewCell {
    
    var delegate: AlarmDetailCellDelegate?
    var weekdayButtonAccessoryView: MultiButton? {
        get {
            guard let weekdayButtonAccessoryView = self.accessoryView as? MultiButton else { return nil }
            return weekdayButtonAccessoryView
        }
    }
    var switchAccessoryView: UISwitch? {
        get {
            guard let switchAccessoryView = self.accessoryView as? UISwitch else { return nil }
            return switchAccessoryView
        }
    }
    
    var cellStyle: AlarmDetailCellStyle = .label {
        didSet {
            self.updateLabels()
            self.setupAccessoryView()
        }
    }
    
    private func updateLabels(){
        self.textLabel?.text = String(describing: self.cellStyle).localizedCapitalized.localized
        self.textLabel?.textColor = UIColor.alarmDarkText
        self.textLabel?.font = UIFont.body
        
        self.detailTextLabel?.text = nil
        self.detailTextLabel?.textColor = UIColor.alarmText
        self.detailTextLabel?.font = UIFont.callout
    }
    
    private func setupAccessoryView(){
        self.accessoryView = nil
        self.backgroundColor = UIColor.alarmDefaultBackgroundColor
        
        switch cellStyle {
        case .repeat:
            let multiButton = MultiButton(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
            multiButton.delegate = self
            multiButton.buttonTitleColor = UIColor.alarmLightText
            multiButton.buttonTitleColorHighlighted = UIColor.white
            multiButton.setTitles(titles: Calendar.current.shortWeekdaySymbols)
            self.accessoryView = multiButton
        
        case .label:
            self.accessoryType = .disclosureIndicator
            
        case .sound:
            self.accessoryType = .disclosureIndicator
            
        case .snooze:
            let snoozeSwitch = UISwitch()
            snoozeSwitch.addTarget(self, action: #selector(self.snoozeSwitchValueChanged(sender:)), for: .valueChanged)
            snoozeSwitch.onTintColor = UIColor.alarmSwitchOnTintColor
            snoozeSwitch.tintColor = UIColor.alarmSwitchTintColor
            self.accessoryView = snoozeSwitch
        }
    }
    
    func snoozeSwitchValueChanged(sender: UISwitch) {
        self.delegate?.alarmDetailCell(self, snoozeSwitchValueChanged: sender)
    }
}

extension AlarmDetailCell: MultiButtonDelegate {
    func multipleButton(_: MultiButton, didButtonTap button: UIButton, at index: Int) {
        button.isSelected = !button.isSelected
        self.delegate?.alarmDetailCell(self, repeatButtonDidTouchUp: button, at: index)
    }
}

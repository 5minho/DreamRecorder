//
//  AlarmDetailTableCell.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 9..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

/// 알람 Detail(Add,Edit)에서 보여줄 Cell Style.
/// repeat, label, sound, snooze 값을 가지고 있으며 각 값은 Cell에서의 위치(row of indexPath)를 나타낸다.
enum AlarmDetailCellStyle: Int {
    case `repeat` = 0
    case label
    case sound
    case snooze
}

/// AlarmDetailCell은 View(UI)만 그리고 해당 값의 변화들의 대한 처리는 Controller에게 맡긴다.
/// 각각의 Controller는 CellForRow단계에서 Cell을 생성할 때 delegate를 할당해주어야 한다.
/// 또한 TableView에서 어떠한 Cell이 선택되었는지는 각 각의 AccessoryView에 tag 값을 주어 확인할 수 있다.
protocol AlarmDetailCellDelegate: NSObjectProtocol {
    func alarmDetailCell(_: AlarmDetailCell, repeatButtonDidTouchUp button: UIButton, at index: Int)
    func alarmDetailCell(_: AlarmDetailCell, snoozeSwitchValueChanged sender: UISwitch)
}

@IBDesignable
class AlarmDetailCell: UITableViewCell {
    
    // MARK: - Properties.
    // - Internal.
    weak var delegate: AlarmDetailCellDelegate?
    
    /// 생성 단계에서 각각의 AccesorryView에 위치한 MultiButton 또는 Switch버튼에 접근에 대한 편의를 제공한다.
    var weekdayButtonAccessoryView: MultiButton? {
        get {
            return self.accessoryView as? MultiButton
        }
    }
    var switchAccessoryView: UISwitch? {
        get {
            return self.accessoryView as? UISwitch
        }
    }
    
    var cellStyle: AlarmDetailCellStyle = .label {
        didSet {
            self.backgroundColor = .dreamBackgroundColor
            self.detailTextLabel?.text = nil
            self.textLabel?.text = String(describing: self.cellStyle).localizedCapitalized.localized
            self.setupAccessoryView()
        }
    }
    
    // - Private.
    lazy var spacingWithTextLabel: CGFloat = 60
    lazy var minimumSpacing: CGFloat = 8
    
    // MARK: - Methods.
    private func setupAccessoryView(){
        self.accessoryView = nil
        
        switch cellStyle {
        case .repeat:
            
            let multiButton = MultiButton(frame: CGRect(x: 0, y: 0, width: 200, height: 50))
            multiButton.delegate = self
            multiButton.buttonTitleColor = UIColor.dreamTextColor3
            multiButton.buttonTitleColorHighlighted = UIColor.dreamTextColor1
            
            self.accessoryView = multiButton
            
            multiButton.setTitles(titles: Calendar.current.shortWeekdaySymbols)

            
        case .label:
            self.accessoryType = .disclosureIndicator
            
        case .sound:
            self.accessoryType = .disclosureIndicator
            
        case .snooze:
            let snoozeSwitch = UISwitch()
            snoozeSwitch.addTarget(self, action: #selector(self.snoozeSwitchValueChanged(sender:)), for: .valueChanged)
            snoozeSwitch.onTintColor = UIColor.dreamBackgroundColorHighlighted
            snoozeSwitch.tintColor = UIColor.dreamBorderColor
            
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

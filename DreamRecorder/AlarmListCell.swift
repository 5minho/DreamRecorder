//
//  AlarmListCell.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 10..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

/// AlarmListCell은 View(UI)만 그리고 활성화 스위치값의 변화에 대한 처리는 Controller에게 맡긴다.
/// 각각의 Controller는 CellForRow단계에서 Cell을 생성할 때 delegate를 할당해주어야 한다.
/// 또한 TableView에서 어떠한 Cell이 선택되었는지는 각 각의 AccessoryView가 되는 UISwitch에 tag 값을 주어 확인할 수 있다.
protocol AlarmListCellDelegate: NSObjectProtocol {
    func alarmListCell(cell: AlarmListCell, activeSwitchValueChanged sender: UISwitch)
}

class AlarmListCell: UITableViewCell {
    
    // MARK: - Properties.
    // - Subviews.
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var weekdayButton: MultiButton!
    @IBOutlet weak var nameLabel: UILabel!
    var activeSwitch: UISwitch!
    
    // - Internal.
    weak var delegate: AlarmListCellDelegate?
    
    // MARK: - Initializer.
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        self.setupAccessoryView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
        self.setupAccessoryView()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupWeekdayButton()
        self.applyViewTheme()
    }
    
    // MARK: Methods.
    /// 뷰에 전체적인 테마를 입힌다.
    private func applyViewTheme() {
        
        self.backgroundColor = UIColor.dreamBackgroundColor
        
        self.timeLabel.textColor = UIColor.dreamTextColor1
        self.nameLabel.textColor = UIColor.dreamTextColor2
        
        self.activeSwitch.tintColor = UIColor.dreamBorderColor
        self.activeSwitch.onTintColor = UIColor.dreamBackgroundColorHighlighted
        
        self.weekdayButton.buttonBackgroundColor = UIColor.dreamBackgroundColor
        self.weekdayButton.buttonTitleColor = UIColor.dreamTextColor3
        self.weekdayButton.buttonTitleColorHighlighted = UIColor.dreamTextColor1
        
        self.timeLabel.font = UIFont.title1
        self.nameLabel.font = UIFont.body
    }
    
    /// MultiButton을 활용하여 Weekday버튼으로 만든다.
    private func setupWeekdayButton(){
        self.weekdayButton.setTitles(titles: Calendar.current.shortWeekdaySymbols)
        self.weekdayButton.distribution = .fillEqually
    }
    
    /// 알람을 활성화 / 비활성화 할 수 있는 UISwitch를 AccessoryView에 추가한다.
    private func setupAccessoryView() {
        self.activeSwitch = UISwitch()
        activeSwitch.addTarget(self, action: #selector(self.activeSwitchValueChanged(sender:)), for: .valueChanged)
        self.accessoryView = activeSwitch
    }
    
    /// AccessoryView에 추가된 UISwitch의 .valueChanged의 핸들러이다.
    /// AlarmListCell은 화면구성만 담당하며 사용자의 액션에 대한 처리는 delegate에게 맡긴다.
    @objc private func activeSwitchValueChanged(sender: UISwitch) {
        self.delegate?.alarmListCell(cell: self, activeSwitchValueChanged: sender)
    }
}


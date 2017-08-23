//
//  AlarmListCell.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 10..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

protocol AlarmListCellDelegate: NSObjectProtocol {
    func alarmListCell(cell: AlarmListCell, activeSwitchValueChanged sender: UISwitch)
}

class AlarmListCell: UITableViewCell {
    
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var weekdayButton: MultiButton!
    @IBOutlet weak var nameLabel: UILabel!
    var activeSwitch: UISwitch!
    
    weak var delegate: AlarmListCellDelegate?
    
    override init(style: UITableViewCellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
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
    
    func applyViewTheme() {
        
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
    
    private func setupWeekdayButton(){
        self.weekdayButton.setTitles(titles: Calendar.current.shortWeekdaySymbols)
        self.weekdayButton.distribution = .fillEqually
    }
    
    private func setupAccessoryView() {
        self.activeSwitch = UISwitch()
        activeSwitch.addTarget(self, action: #selector(self.activeSwitchValueChanged(sender:)), for: .valueChanged)
        self.accessoryView = activeSwitch
    }
    
    @objc private func activeSwitchValueChanged(sender: UISwitch) {
        self.delegate?.alarmListCell(cell: self, activeSwitchValueChanged: sender)
    }
}


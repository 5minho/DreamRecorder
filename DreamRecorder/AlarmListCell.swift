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
//        self.setupWeekdayButton()
        self.setupAccessoryView()
    }
    
    required init?(coder aDecoder: NSCoder) {
        super.init(coder: aDecoder)
//        self.setupWeekdayButton()
        self.setupAccessoryView()
    }
    
    override func awakeFromNib() {
        super.awakeFromNib()
        self.setupWeekdayButton()
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

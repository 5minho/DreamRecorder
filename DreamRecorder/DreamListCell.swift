//
//  DreamListCell.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 13..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class DreamListCell : UITableViewCell {
    
    @IBOutlet weak var dayLabel: UILabel!
    @IBOutlet weak var monthLabel: UILabel!
    @IBOutlet weak var timeLabel: UILabel!
    @IBOutlet weak var dreamTitleLabel: UILabel!
    
    override func awakeFromNib() {
        super.awakeFromNib()
    }
    
    func update(dream: Dream) {
        
        let dateParser = DateParser()
        self.dayLabel.text = dateParser.day(from: dream.createdDate)
        self.monthLabel.text = dateParser.month(from: dream.createdDate)
        self.timeLabel.text = dateParser.time(from: dream.createdDate)
        self.dreamTitleLabel.text = dream.title ?? ""
        
        applyViewTheme()
    }
    
    func applyViewTheme() {
        
        self.backgroundColor = UIColor.dreamBackgroundColor
        
        self.dayLabel.textColor = UIColor.dreamTextColor1
        self.monthLabel.textColor = UIColor.dreamTextColor1
        self.timeLabel.textColor = UIColor.dreamTextColor1
        self.dreamTitleLabel.textColor = UIColor.dreamTextColor1
        
        self.dayLabel.font = UIFont.title1
        self.monthLabel.font = UIFont.title3
        self.timeLabel.font = UIFont.caption1
        self.dreamTitleLabel.font = UIFont.title3
       
    }
    
}

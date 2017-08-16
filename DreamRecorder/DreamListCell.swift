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
    
    func update(dream: Dream) {
        
        let dateParser = DateParser()
        self.dayLabel.text = dateParser.day(from: dream.createdDate)
        self.monthLabel.text = dateParser.month(from: dream.createdDate)
        self.timeLabel.text = dateParser.time(from: dream.createdDate)
        self.dreamTitleLabel.text = dream.title ?? ""
        
    }
    
}

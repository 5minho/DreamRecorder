//
//  DreamColor.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 16..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

extension UIColor {
    
//    static let alarmBlue = UIColor(red:0.55, green:0.62, blue:0.76, alpha:1.00)
//    static let alarmDarkBlue = UIColor(red:0.27, green:0.35, blue:0.49, alpha:1.00)
//    static let alarmLightBlue = UIColor(red:0.64, green:0.70, blue:0.81, alpha:1.00)
    static let alarmBlue = UIColor(red:0.07, green:0.29, blue:0.51, alpha:1.00)
    static let alarmLightBlue = UIColor(red:0.07, green:0.29, blue:0.54, alpha:1.00)
    static let alarmDarkBlue = UIColor(red:0.01, green:0.05, blue:0.12, alpha:1.00)
    static let alarmHighlightBlue = UIColor(red:0.07, green:0.29, blue:0.54, alpha:1.00)
    static let alarmUnHighlightBlue = UIColor(red:0.24, green:0.34, blue:0.52, alpha:1.00)
    
    // NEW.
    static let dreamBackgroundColor = UIColor(red:0.01, green:0.05, blue:0.12, alpha:1.00)
    static let dreamBackgroundColorHighlighted = UIColor(red:0.02, green:0.15, blue:0.34, alpha:1.00)
    
    static let dreamBorderColor = UIColor(red:0.07, green:0.29, blue:0.51, alpha:1.00)
    
    static let dreamTextColor1 = UIColor(red:0.91, green:0.93, blue:0.95, alpha:1.00)
    static let dreamTextColor2 = UIColor(red:0.53, green:0.61, blue:0.79, alpha:1.00)
    static let dreamTextColor3 = UIColor(red:0.31, green:0.44, blue:0.60, alpha:1.00)
    
    
//    static let alarmText = UIColor(red:0.40, green:0.43, blue:0.50, alpha:1.00)
//    static let alarmDarkText = UIColor(red:0.29, green:0.29, blue:0.29, alpha:1.00)
//    static let alarmLightText = UIColor(red:0.69, green:0.73, blue:0.83, alpha:1.00)
    static let alarmText = UIColor(red:0.53, green:0.61, blue:0.79, alpha:1.00)
    static let alarmDarkText = UIColor.white
    static let alarmLightText = UIColor(red:0.69, green:0.73, blue:0.83, alpha:1.00)
    
    static let dreamPink = UIColor(red:0.97, green:0.79, blue:0.79, alpha:1.00)
    static let dreamLightPink = UIColor(red:0.99, green:0.91, blue:0.92, alpha:1.00)
    static let dreamDarkPink = UIColor(red:0.93, green:0.62, blue:0.62, alpha:1.00)
    
    static let dreamText = UIColor(red:0.37, green:0.35, blue:0.35, alpha:1.00)
    static let dreamDarkText = UIColor(red:0.38, green:0.32, blue:0.32, alpha:1.00)
    static let dreamLightText = UIColor(red:0.68, green:0.58, blue:0.57, alpha:1.00)
      
    // Alarm Background Color
    static var dreamDefaultBackgroundColor: UIColor { return dreamPink }
    static var dreamSwitchOnTintColor: UIColor { return dreamDarkPink}
    static var dreamSwitchTintColor: UIColor { return dreamLightPink }
    static var dreamNavigationBarShadowColor: UIColor { return dreamLightPink }
    static var dreamTableViewSeparatorColor: UIColor { return dreamLightPink }
    
    // Alarm Text Color
    static var dreamButtonTitleColor: UIColor { return UIColor.white }
    static var dreamCellTitleColor: UIColor { return dreamDarkText }
    static var dreamCellCaptionColor: UIColor { return dreamLightText }
    static var dreamCellBodyColor: UIColor { return dreamText }
    
    // Default
    static var defaultButtonTitleColor: UIColor { return UIColor.white }
}

//
//  AlarmThemeAppliable.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 17..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

enum ThemeStyle {
    case dream
    case alarm
}

protocol ThemeAppliable {
    var themeStyle: ThemeStyle { get }
    var view : UIView! {get}
    var themeTableView: UITableView? { get }
    var themeNavigationController: UINavigationController? { get }
    
    // call this procol function endline of viewDidLoad
    func applyTheme()
}

extension ThemeAppliable {
    func applyTheme(){
        if themeStyle == .dream {
            self.view.backgroundColor = UIColor.dreamDefaultBackgroundColor
            self.themeTableView?.tableFooterView = UIView(frame: .zero)
            self.themeTableView?.separatorColor = UIColor.dreamTableViewSeparatorColor
            self.themeTableView?.backgroundColor = UIColor.dreamDefaultBackgroundColor
            
            self.themeNavigationController?.navigationBar.backgroundColor = UIColor.dreamDefaultBackgroundColor
            self.themeNavigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            self.themeNavigationController?.navigationBar.shadowImage = self.shadowImage(with: UIColor.dreamNavigationBarShadowColor)
            self.themeNavigationController?.navigationBar.barTintColor = UIColor.dreamDefaultBackgroundColor
            self.themeNavigationController?.navigationBar.isTranslucent = false
        } else {
            self.themeTableView?.tableFooterView = UIView(frame: .zero)
            self.themeTableView?.separatorColor = UIColor.alarmTableViewSeparatorColor
            self.themeTableView?.backgroundColor = UIColor.alarmDefaultBackgroundColor
            
            self.themeNavigationController?.navigationBar.backgroundColor = UIColor.alarmDefaultBackgroundColor
            self.themeNavigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
            self.themeNavigationController?.navigationBar.shadowImage = self.shadowImage(with: UIColor.alarmNavigationBarShadowColor)
            self.themeNavigationController?.navigationBar.barTintColor = UIColor.alarmDefaultBackgroundColor
            self.themeNavigationController?.navigationBar.isTranslucent = false
        }
    }
    
    private func shadowImage(with color: UIColor) -> UIImage{
        defer {
            UIGraphicsEndImageContext()
        }
        
        let size = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(size, false, 0);
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: CGSize(width: 1, height: 1)))
        let filledImage = UIGraphicsGetImageFromCurrentImageContext()
        let shadowImage = filledImage ?? UIImage()
        return shadowImage
    }
}

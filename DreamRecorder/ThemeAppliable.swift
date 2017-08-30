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
    var themeStyle: ThemeStyle { get }          // UIViewController가 어떠한 테마를 적용할 지 결정한다.
    var themeTableView: UITableView? { get }    // 만약 UIViewController가 UITableView를 가지고 있으면 해당 UITableView를 반환시켜 테마를 적용할 수 있다.
    
    func applyThemeIfViewDidLoad()
}

extension ThemeAppliable where Self: UIViewController {

    /// viewWillAppear() 안에서 applyTheme()을 호출하면 tabBarController에 커스텀 색상 테마를 적용한다.
    func applyThemeIfViewDidLoad(){
        // 공통 테마.
        self.tabBarController?.tabBar.isTranslucent = false
        self.themeTableView?.tableFooterView = UIView(frame: .zero)
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        self.navigationController?.navigationBar.titleTextAttributes = [NSForegroundColorAttributeName: UIColor.white]
        
            
        let shadowImage = UIColor.dreamBorderColor.shadowImage()
        
        self.navigationController?.navigationBar.backgroundColor = UIColor.dreamBackgroundColor
        self.navigationController?.navigationBar.shadowImage = shadowImage
        self.navigationController?.navigationBar.barTintColor = UIColor.dreamBackgroundColor
        
        self.view.backgroundColor = UIColor.dreamBackgroundColor
        
        self.themeTableView?.separatorColor = UIColor.dreamBorderColor
        self.themeTableView?.backgroundColor = UIColor.dreamBackgroundColor
        
        if #available(iOS 10.0, *) {
            self.tabBarController?.tabBar.unselectedItemTintColor = UIColor.dreamTextColor2
        }
    }
}

extension UITableViewCell {
    open override func awakeFromNib() {
        super.awakeFromNib()
        self.applyDreamTheme()
    }
    
    func applyDreamTheme() {
        self.contentView.backgroundColor = UIColor.dreamBackgroundColor
        self.backgroundColor = UIColor.dreamBackgroundColor
        self.tintColor = UIColor.dreamTextColor1
        self.textLabel?.textColor = UIColor.dreamTextColor1
        self.textLabel?.font = UIFont.body
        self.detailTextLabel?.textColor = UIColor.dreamTextColor2
        self.detailTextLabel?.font = UIFont.callout
    }
}

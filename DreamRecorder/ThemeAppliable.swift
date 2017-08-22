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
    var themeStyle: ThemeStyle { get }              // UIViewController가 어떠한 테마를 적용할 지 결정한다.
    var themeTableView: UITableView? { get }        // 만약 UIViewController가 UITableView를 가지고 있으면 해당 UITableView를 반환시켜 테마를 적용할 수 있다.
    
    /// viewDidLoad() 안에서 applyTheme()을 호출하면 커스텀 색상 테마를 적용할 수 있다.
    func applyThemeIfViewDidLoad()
    func applyThemeIfViewWillAppear()
}

extension ThemeAppliable where Self: UIViewController {
    
    /// Description 화면이 보여질때마다 적용할 테마를 입힌다.
    func applyThemeIfViewWillAppear() {
        // 각각의 테마 적용.
        if themeStyle == .dream {
            let shadowImage = self.shadowImage(with: UIColor.dreamNavigationBarShadowColor)
            
            self.tabBarController?.tabBar.barTintColor = UIColor.dreamDefaultBackgroundColor
            self.tabBarController?.tabBar.backgroundImage = UIImage()
            self.tabBarController?.tabBar.shadowImage = shadowImage
            self.tabBarController?.tabBar.tintColor = UIColor.white
        } else {
            let shadowImage = self.shadowImage(with: UIColor.alarmNavigationBarShadowColor)
            
            self.tabBarController?.tabBar.barTintColor = UIColor.alarmDefaultBackgroundColor
            self.tabBarController?.tabBar.backgroundImage = UIImage()
            self.tabBarController?.tabBar.shadowImage = shadowImage
            self.tabBarController?.tabBar.tintColor = UIColor.white
        }
    }

    /// Description View가 로드되면 적용할 테마를 입힌다.
    func applyThemeIfViewDidLoad(){
        // 공통 테마.
        self.tabBarController?.tabBar.isTranslucent = false
        self.themeTableView?.tableFooterView = UIView(frame: .zero)
        self.navigationController?.navigationBar.isTranslucent = false
        self.navigationController?.navigationBar.setBackgroundImage(UIImage(), for: .default)
        
        // 각각의 테마 적용.
        if themeStyle == .dream {
            let shadowImage = self.shadowImage(with: UIColor.dreamNavigationBarShadowColor)
            
            self.navigationController?.navigationBar.backgroundColor = UIColor.dreamDefaultBackgroundColor
            self.navigationController?.navigationBar.shadowImage = shadowImage
            self.navigationController?.navigationBar.barTintColor = UIColor.dreamDefaultBackgroundColor
            
            self.view.backgroundColor = UIColor.dreamDefaultBackgroundColor
            
            self.themeTableView?.separatorColor = UIColor.dreamTableViewSeparatorColor
            self.themeTableView?.backgroundColor = UIColor.dreamDefaultBackgroundColor
            
            if #available(iOS 10.0, *) {
                self.tabBarController?.tabBar.unselectedItemTintColor = UIColor.dreamText
            }
        } else {
            let shadowImage = self.shadowImage(with: UIColor.alarmNavigationBarShadowColor)
            
            self.navigationController?.navigationBar.backgroundColor = UIColor.alarmDefaultBackgroundColor
            self.navigationController?.navigationBar.shadowImage = shadowImage
            self.navigationController?.navigationBar.barTintColor = UIColor.alarmDefaultBackgroundColor
            
            self.view.backgroundColor = UIColor.alarmDefaultBackgroundColor
            
            self.themeTableView?.separatorColor = UIColor.alarmTableViewSeparatorColor
            self.themeTableView?.backgroundColor = UIColor.alarmDefaultBackgroundColor
            
            if #available(iOS 10.0, *) {
                self.tabBarController?.tabBar.unselectedItemTintColor = UIColor.alarmText
            }
        }
    }
    
    /// 한가지 색상을 이용하여 1x1의 이미지를 생성한다.
    /// UIGraphicsGetImageFromCurrentImageContext()를 통해 이미지를 얻지 못할 경우에는 UIImage()를 반환한다.
    ///
    /// - Parameter color: UIImage의 배경색상에 활용 될 UIColor.
    /// - Returns: 파라미터로 전달된 UIColor를 통해 1x1의 이미지를 반환한다.
    private func shadowImage(with color: UIColor) -> UIImage {
        defer {
            UIGraphicsEndImageContext()
        }
        
        let imageContextSize = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(imageContextSize, false, 0)
        color.setFill()
        UIRectFill(CGRect(origin: .zero, size: CGSize(width: 1, height: 1)))
        let filledImage = UIGraphicsGetImageFromCurrentImageContext()
        return filledImage ?? UIImage()
    }
}

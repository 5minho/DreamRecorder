//
//  MainTabBarViewController.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 10..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class MainTabBarViewController: UITabBarController {

    override func viewDidLoad() {
        super.viewDidLoad()

        let shadowImage = UIColor.dreamBorderColor.shadowImage()
        
        self.tabBar.backgroundImage = UIImage()
        self.tabBar.barTintColor = UIColor.dreamBackgroundColor
        self.tabBar.shadowImage = shadowImage
        self.tabBar.tintColor = UIColor.white
        
        // DreamController, AlarmController, SettingController.
        guard let controllers = self.viewControllers else { return }
        
        let titles = [TabbarTitle.dreamTab, TabbarTitle.alarmTab, TabbarTitle.settingTab.localized]
        let iconImages = [#imageLiteral(resourceName: "icon_moon"), #imageLiteral(resourceName: "musical32"), #imageLiteral(resourceName: "cog2")]
        let iconSize = CGSize(width: 25, height: 25)
        
        for (index, controller) in controllers.enumerated() {
            controller.tabBarItem.image = iconImages[index].withRenderingMode(.alwaysTemplate).image(with: iconSize)
            controller.title = titles[index]
        }
        
        
    }
}

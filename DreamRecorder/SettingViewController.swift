//
//  SettingViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 24..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class SettingViewController: UIViewController {
    
    @IBOutlet weak var tableView: UITableView!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.applyThemeIfViewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 44
        
        self.tableView.backgroundColor = UIColor.dreamBackgroundColor
        self.tableView.tableFooterView = UIView(frame: .zero)
        
        self.title = NavigationTitle.setting
        
        /// 각 각의 설정페이지에서 설정 값이 바뀌었을 경우 Notification을 통해 UITableView를 리로드한다.
        NotificationCenter.default.addObserver(forName: .DreamRecorderFontDidChange,
                                               object: nil,
                                               queue: .main)
        { (_) in
            self.tableView.reloadData()
        }
        
        NotificationCenter.default.addObserver(forName: .DreamRecorderLanguageDidChange,
                                               object: nil,
                                               queue: .main) { (_) in
            self.tableView.reloadData()
        }
    }
}

extension SettingViewController: UITableViewDelegate, UITableViewDataSource {
    
    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
        let headerLabel = UILabel(frame: .zero)
        headerLabel.backgroundColor = .dreamBackgroundColor
        headerLabel.textColor = .dreamTextColor3
        headerLabel.text = (section == 0) ? "Dream".localized : "Alarm".localized
        headerLabel.font = .caption1
        
        return headerLabel
    }
    
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        
        if section == 0 {
            return 1
        } else if section == 1 {
            return 2
        } else {
            return 0
        }
        
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.uitableViewCell, for: indexPath)
        
        /// 커스터마이징 셀.
        cell.detailTextLabel?.textColor = .dreamTextColor3
        cell.detailTextLabel?.font = .callout
        cell.textLabel?.textColor = .dreamTextColor1
        cell.textLabel?.font = .body
        cell.tintColor = .dreamTextColor1
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                
                /// 언어 설정 셀.
                cell.textLabel?.text = "Language".localized
                cell.detailTextLabel?.text = UserLangauge.names[UserDefaults.standard.integer(forKey: Key.speechLangaugeKey)]
                
                let iconHeight = cell.frame.height - 32
                let iconSize = CGSize(width: iconHeight, height: iconHeight)
                let iconImage = #imageLiteral(resourceName: "earth17").image(with: iconSize)?.withRenderingMode(.alwaysTemplate)
                cell.imageView?.image = iconImage

            default:
                break
            }
        default:
            
            switch indexPath.row {
                
            case 0:
                
                /// 폰트 설정 셀.
                cell.textLabel?.text = "Font".localized
                cell.detailTextLabel?.text = UserDefaults.standard.string(forKey: UserDefaults.UserKey.fontName) ?? "System"
                
                let iconHeight = cell.frame.height - 32
                let iconSize = CGSize(width: iconHeight, height: iconHeight)
                let iconImage = #imageLiteral(resourceName: "font3").image(with: iconSize)?.withRenderingMode(.alwaysTemplate)
                cell.imageView?.image = iconImage
            
            case 1:
                
                /// 노티피케이션 설정 셀.
                cell.textLabel?.text = "Notification Privacy".localized
                cell.detailTextLabel?.text = ""
                
            default:
                break
            }
        }
        return cell
    }
    
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                /// 언어 설정 클릭.
                let languageListViewController = LanguageListViewController(style: .plain)
                self.navigationController?.pushViewController(languageListViewController, animated: true)
            default:
                break
            }
            break
        case 1:
            switch indexPath.row {
            case 0:
                /// 폰트 설정 클릭.
                let fontListViewController = FontListViewController(style: .plain)
                self.navigationController?.pushViewController(fontListViewController, animated: true)
                
            case 1:
                /// 노티피케이션 설정 클릭.
                guard let profileUrl = URL(string: "App-Prefs:root=NOTIFICATIONS_ID") else { return }
                
                if UIApplication.shared.canOpenURL(profileUrl) {
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(profileUrl, completionHandler: nil)
                    } else {
                        UIApplication.shared.openURL(profileUrl)
                    }
                }
                
            default:
                break
            }
        default:
            break
        }
    }
}

extension SettingViewController: ThemeAppliable {
    // MARK: - ThemeAppliable.
    var themeStyle: ThemeStyle {
        return .alarm
    }
    var themeTableView: UITableView? {
        return self.tableView
    }
}

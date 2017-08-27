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
        
        self.title = "Setting".localized
        
        NotificationCenter.default.addObserver(forName: Notification.Name.DreamRecorderFontDidChange,
                                               object: nil,
                                               queue: .main)
        { (_) in
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
            return 3
        } else {
            return 0
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        
        cell.detailTextLabel?.textColor = .dreamTextColor3
        cell.detailTextLabel?.font = .callout
        cell.textLabel?.textColor = .dreamTextColor1
        cell.textLabel?.font = .body
        cell.tintColor = .dreamTextColor1
        
        switch indexPath.section {
        case 0:
            switch indexPath.row {
            case 0:
                
                cell.textLabel?.text = "Language".localized
                cell.detailTextLabel?.text = "Korea"
                
                let iconHeight = cell.frame.height - 32
                let iconSize = CGSize(width: iconHeight, height: iconHeight)
                let iconImage = #imageLiteral(resourceName: "icon_earth").image(with: iconSize)?.withRenderingMode(.alwaysTemplate)
                cell.imageView?.image = iconImage

            default:
                break
            }
        default:
            
            switch indexPath.row {
                
            case 0:
                
                cell.textLabel?.text = "Font".localized
                cell.detailTextLabel?.text = UserDefaults.standard.string(forKey: UserDefaults.UserKey.fontName)
                
                let iconHeight = cell.frame.height - 32
                let iconSize = CGSize(width: iconHeight, height: iconHeight)
                let iconImage = #imageLiteral(resourceName: "icon_font").image(with: iconSize)?.withRenderingMode(.alwaysTemplate)
                cell.imageView?.image = iconImage
            
            case 1:
                
                cell.textLabel?.text = "Privacy Notification"
                
                
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
            break
        case 1:
            switch indexPath.row {
            case 0:
                let fontListViewController = FontListViewController(style: .plain)
                self.navigationController?.pushViewController(fontListViewController, animated: true)
                
            case 1:
                guard let profileUrl = URL(string:
                    "App-Prefs:root=NOTIFICATIONS_ID") else {
                        return
                }
                
                if UIApplication.shared.canOpenURL(profileUrl) {
                    
                    if #available(iOS 10.0, *) {
                        UIApplication.shared.open(profileUrl, completionHandler: { (success) in
                            
                            print(" Profile Settings opened: \(success)")
                            
                        })
                    } else {
                        // Fallback on earlier versions
                        UIApplication.shared.openURL(profileUrl)
                    }
                } else {
                    if let url = URL(string: UIApplicationOpenSettingsURLString) {
                        if #available(iOS 10.0, *) {
                            UIApplication.shared.open(url, options: [:], completionHandler: { (completed) in
                                    
                            })
                        } else {
                            // Fallback on earlier versions
                        }
                    }
                }
            case 2:
                
                AlarmScheduler.shared.nextTriggerDate(completionHandler: { (identifier, date) in
                    if let nextDate = date {
                        DispatchQueue.main.async {
                            let shareItem = "HelloWorld"
                            let alarmTime = nextDate.description
                            let controller = UIActivityViewController(activityItems: [shareItem, alarmTime],
                                                                      applicationActivities: nil)
                            controller.popoverPresentationController?.sourceView = tableView.cellForRow(at: indexPath)
                            controller.excludedActivityTypes = [UIActivityType.message]
                            self.present(controller, animated: true, completion: nil)
                        }
                    }
                })
                
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

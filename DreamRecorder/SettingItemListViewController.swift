//
//  SettingItemListViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 24..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit
protocol SettingItemListViewControllerDelegate: NSObjectProtocol {
    var items: [String] { get }
    var currentItem: String? { get }
}

class SettingItemListViewController: UITableViewController {
    
    weak var delegate: SettingItemListViewControllerDelegate?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.view.backgroundColor = UIColor.dreamBackgroundColor
        self.tableView.tableFooterView = UIView(frame: .zero)
        self.tableView.separatorColor = UIColor.dreamBorderColor
        self.tableView.backgroundColor = UIColor.dreamBackgroundColor
    }
    
    override func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.delegate?.items.count ?? 0
    }
    
    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = UITableViewCell(style: .value1, reuseIdentifier: "UITableViewCell")
        
        cell.backgroundColor = UIColor.dreamBackgroundColor
        cell.tintColor = .dreamTextColor1
        cell.textLabel?.textColor = .dreamTextColor1
        cell.textLabel?.font = .body
        cell.detailTextLabel?.textColor = .dreamTextColor3
        cell.detailTextLabel?.font = .callout
        
        if let items = self.delegate?.items {
           
            let item = items[indexPath.row]
            cell.textLabel?.text = item
            
            if let currentItem = self.delegate?.currentItem {
                cell.accessoryType = (item == currentItem) ? .checkmark : .none
            }
            
            return cell
        } else {
            return cell
        }
    }
}

extension Notification.Name {
    static let DreamRecorderFontDidChange = Notification.Name("DreamRecorderFontDidChange")
}

class FontListViewController: SettingItemListViewController, SettingItemListViewControllerDelegate {
    
    var items: [String] = CustomFont.current.userFontNames
    var currentItem: String? = UserDefaults.standard.string(forKey: UserDefaults.UserKey.fontName) ?? "System"

    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.delegate = self
    }
    
    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        UserDefaults.standard.setValue(items[indexPath.row], forKey: UserDefaults.UserKey.fontName)
        CustomFont.current.reloadFont()
        NotificationCenter.default.post(name: Notification.Name.DreamRecorderFontDidChange, object: nil)
        self.navigationController?.popViewController(animated: true)
    }
}

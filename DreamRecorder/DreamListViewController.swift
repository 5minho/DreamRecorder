//
//  DreamListViewController.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 8..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class DreamListViewController : UIViewController {
    
    @IBOutlet weak var tableView: UITableView!

    override func viewDidLoad() {
        super.viewDidLoad()
        self.applyTheme()
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.navigationItem.leftBarButtonItem = editButtonItem
        
        NotificationCenter.default.addObserver(forName: DreamDataStore.NotificationName.didDeleteDream, object: nil, queue: .main) {
            notification in
            if let row = notification.userInfo?["index"] as? Int {
                self.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
            }
        }
        
        NotificationCenter.default.addObserver(forName: DreamDataStore.NotificationName.didAddDream, object: nil, queue: .main) {
            notification in
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
//            self.tableView.reloadData()
        }
        
        
    }
    
    deinit {
        NotificationCenter.default.removeObserver(self)
    }
    
    override func viewWillAppear(_ animated: Bool) {
    
        super.viewWillAppear(animated)
        tableView.reloadSections(IndexSet(integersIn:0...0), with: .automatic)
        
    }

    @IBAction func addDream(_ sender: UIBarButtonItem) {
        
        if let addDreamNavigationController = AddDreamNavigationController.storyboardInstance() {
            present(addDreamNavigationController, animated: true, completion: nil)
        }
        
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(!self.tableView.isEditing, animated: true)
        
    }
    
}

extension DreamListViewController : UITableViewDelegate, UITableViewDataSource, DreamDeletable {
    
    // MARK: - Table view dataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return DreamDataStore.shared.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DreamListCell", for: indexPath) as? DreamListCell else {
            return UITableViewCell()
        }
        
        if let dream = DreamDataStore.shared.dream(at: indexPath.row) {
            cell.update(dream: dream)
        }
    
        return cell
    }
    
    // MARK: - Table view delegate
  
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let detailDreamViewController = DetailDreamViewController.storyboardInstance() {
            
            detailDreamViewController.dream = DreamDataStore.shared.dream(at: indexPath.row)
            navigationController?.pushViewController(detailDreamViewController, animated: true)
            
        }
        
    }

    // 
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteButton = UITableViewRowAction(style: .destructive, title: "삭제") { action, indexPath -> Void in
            
            if let dream = DreamDataStore.shared.dream(at: indexPath.row) {
                let alert = self.deleteAlert(dream: dream, completion: nil)
                self.present(alert, animated: true, completion: nil)
            }
            
        }
    
        let pinButton = UITableViewRowAction(style: .normal, title: "pin") { (action, indexPath) in
            print("pin")
        }
        
        deleteButton.backgroundColor = UIColor.blue
        pinButton.backgroundColor = UIColor.purple
        
        return [deleteButton, pinButton]
    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 80
    }
    
}

extension DreamListViewController : ThemeAppliable {
    var themeStyle: ThemeStyle {
        return .dream
    }
    
    var themeTableView: UITableView? {
        return self.tableView
    }
    var themeNavigationController: UINavigationController? {
        return self.navigationController
    }
}

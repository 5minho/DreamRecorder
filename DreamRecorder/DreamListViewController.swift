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
    var dreamDataStore : DreamDataStore!
    
    fileprivate var dateParser = DateParser()
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        let mainTabBarController = self.tabBarController as? MainTabBarViewController
        dreamDataStore = mainTabBarController?.dreamDataStore
        
        tableView.delegate = self
        tableView.dataSource = self
        automaticallyAdjustsScrollViewInsets = false
        
        let header = UIView(frame: CGRect(x: 0, y: 0, width: tableView.frame.width, height : 100))
        header.backgroundColor = UIColor.red
        tableView.tableHeaderView = header
        tableView.register(DreamListCell.self, forCellReuseIdentifier: "DreamListCell")
    }
    
    override func viewWillAppear(_ animated: Bool) {
    
        super.viewWillAppear(animated)
        tableView.reloadSections(IndexSet(integersIn:0...0), with: .automatic)
        
    }

    @IBAction func addDream(_ sender: UIBarButtonItem) {
        
        if let addDreamNavigationController = AddDreamNavigationController.storyboardInstance() {
            addDreamNavigationController.dreamDataStore = self.dreamDataStore
            present(addDreamNavigationController, animated: true, completion: nil)
        }
        
    }
    
}

extension DreamListViewController : UITableViewDelegate, UITableViewDataSource {
    
    // MARK: - Table view dataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dreamDataStore.dreams.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "DreamListCell", for: indexPath) as! DreamListCell
        let leftButton = cell.createButton(with: 100, side: .left)
        leftButton.backgroundColor = .blue
        
        let rightButton = cell.createButton(with: 80, side: .right)
        rightButton.backgroundColor = .red
//        let row = indexPath.row
//
//        cell.dayLabel.text = dateParser.day(from: dreamDataStore.dreams[row].createdDate)
//        cell.monthLabel.text = dateParser.month(from: dreamDataStore.dreams[row].createdDate)
//        cell.timeLabel.text = dateParser.time(from: dreamDataStore.dreams[row].createdDate)
//        cell.titleLabel.text = dreamDataStore.dreams[row].title
        
        return cell
    }
    
    // MARK: - Table view delegate
  
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        if let detailDreamViewController = DetailDreamViewController.storyboardInstance() {
            detailDreamViewController.dream = dreamDataStore.dreams[indexPath.row]
            detailDreamViewController.dreamDataStore = dreamDataStore
            navigationController?.pushViewController(detailDreamViewController, animated: true)
        }
        
    }
    
//    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
//        
//        if editingStyle == .delete {
//            let dream = dreamDataStore.dreams[indexPath.row]
//            let title = "Delete \(dream.title!)?"
//            let message = "Are you sure you want to delete this item?"
//            
//            let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
//            let cencelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
//            alert.addAction(cencelAction)
//            
//            let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: {
//                [unowned self, tableView] (action) -> Void in
//                self.dreamDataStore.delete(dream: dream, at: indexPath.row)
//                tableView.deleteRows(at: [indexPath], with: .automatic)
//            })
//            alert.addAction(deleteAction)
//            present(alert, animated: true, completion: nil)
//        }
//    }
//
//    func tableView(_ tableView: UITableView, viewForHeaderInSection section: Int) -> UIView? {
//    
//    }
    
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 100
    }
    
//    func tableView(_ tableView: UITableView, willDisplay cell: UITableViewCell, forRowAt indexPath: IndexPath) {
//        cell.responds(to: #selector(cell.separatorInset(_:))) {
//            cell.separatorInset = .zero
//        }
//    }
    
//    - (void)tableView:(UITableView *)tableView willDisplayCell:(UITableViewCell *)cell forRowAtIndexPath:(NSIndexPath *)indexPath {
//    // Remove insets and margins from cells.
//    if ([cell respondsToSelector:@selector(setSeparatorInset:)]) {
//    [cell setSeparatorInset:UIEdgeInsetsZero];
//    }
//    
//    if ([cell respondsToSelector:@selector(setPreservesSuperviewLayoutMargins:)]) {
//    [cell setPreservesSuperviewLayoutMargins:NO];
//    }
//    
//    if ([cell respondsToSelector:@selector(setLayoutMargins:)]) {
//    [cell setLayoutMargins:UIEdgeInsetsZero];
//    }
//    }
    
    
}

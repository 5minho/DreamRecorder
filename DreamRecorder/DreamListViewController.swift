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
    @IBOutlet weak var messageLabel: UILabel!
    @IBOutlet weak var weekDayLabel: UILabel!
    @IBOutlet weak var detailTodayLabel: UILabel!
    
    var dreamDataStore = DreamDataStore()
    
    fileprivate var dateParser = DateParser()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        tableView.delegate = self
        tableView.dataSource = self
        dreamDataStore.selectAll()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        let today = Date()
        weekDayLabel.text = dateParser.dayOfWeek(from: today)
        detailTodayLabel.text = dateParser.detail(from: today)
    }

    @IBAction func addDream(_ sender: UIBarButtonItem) {
        if let speechDreamViewController = SpeechDreamViewController.storyboardInstance() {
            navigationController?.pushViewController(speechDreamViewController, animated: true)
        }
    }
}

extension DreamListViewController : UITableViewDelegate, UITableViewDataSource {
    // MARK: - Table view dataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return dreamDataStore.dreams.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "DreamTableCell", for: indexPath) as! DreamListCell
        let row = indexPath.row
        
        cell.dayLabel.text = dateParser.day(from: dreamDataStore.dreams[row].createdDate)
        cell.monthLabel.text = dateParser.month(from: dreamDataStore.dreams[row].createdDate)
        cell.timeLabel.text = dateParser.time(from: dreamDataStore.dreams[row].createdDate)
        cell.titleLabel.text = dreamDataStore.dreams[row].title
        
        return cell
    }
    
    // MARK: - Table view delegate
    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
    
    func tableView(_ tableView: UITableView, estimatedHeightForRowAt indexPath: IndexPath) -> CGFloat {
        return 75
    }
}

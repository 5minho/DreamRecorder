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
    @IBOutlet weak var dateButton: UIBarButtonItem!
    
    fileprivate var searchController : UISearchController!
    
    fileprivate var filteredDreams = [Dream]()
    fileprivate let dateParser = DateParser()
    
    fileprivate let concurrentQueue = DispatchQueue(label: "filtering", attributes: .concurrent)
    fileprivate var isQueueEmpty = true
    
    var currentViewedDate = Date() {
        
        didSet {
            
            if let fromYear = dateParser.year(from: currentViewedDate) { 
                let fromMonth : Int = dateParser.month(from: currentViewedDate)
                
                var toYear = fromYear
                var toMonth = fromMonth + 1
                
                if fromMonth == 12 {
                    
                    toMonth = 1
                    toYear = fromYear + 1
                    
                }
                
                DreamDataStore.shared.select(fromYear: fromYear,
                                             fromMonth: fromMonth,
                                             toYear: toYear,
                                             toMonth: toMonth)
                
                self.navigationItem.title = "\(fromYear).\(fromMonth)"
                self.tableView.reloadSections(IndexSet(integersIn: 0...0), with: .automatic)
            }
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.applyThemeIfViewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.allowsSelectionDuringEditing = true
        self.dateButton.title = "Date".localized
        self.navigationItem.leftBarButtonItem = editButtonItem
        
        if let year = self.dateParser.year(from: currentViewedDate) {
            
            let month : Int = self.dateParser.month(from: currentViewedDate)
            self.navigationItem.title = "\(year).\(month)"
            
        }
        
        self.addObserver()
        self.setSearchViewController()
    }
    
    
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        self.applyThemeIfViewWillAppear()
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(!self.tableView.isEditing, animated: true)
        
    }
    
    deinit {
        
        NotificationCenter.default.removeObserver(self)
        
    }

    @IBAction func addDream(_ sender: UIBarButtonItem) {
        
        if let addDreamNavigationController = AddDreamNavigationController.storyboardInstance() {
            present(addDreamNavigationController, animated: true, completion: nil)
        }
        
    }
    
    private func addObserver() {
        
        NotificationCenter.default.addObserver(forName: DreamDataStore.NotificationName.didDeleteDream, object: nil, queue: .main) {
            notification in
            
            if self.isFiltering() {
                
                if let row = notification.userInfo?["rowInFiltering"] as? Int {
                    self.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
                }
                
            } else {
                
                if let row = notification.userInfo?["row"] as? Int {
                    self.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
                }
                
            }
            
            
        }
        
        NotificationCenter.default.addObserver(forName: DreamDataStore.NotificationName.didAddDream, object: nil, queue: .main) {
            notification in
            
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
            self.currentViewedDate = Date()
            
        }
        
    }
    
    private func setSearchViewController() {
        
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.searchBar.placeholder = "꿈 제목, 꿈 내용 검색"
        definesPresentationContext = true
        self.searchController.searchBar.delegate = self
        
        self.tableView?.tableHeaderView = searchController?.searchBar
        self.tableView.contentOffset =  CGPoint(x: 0, y: searchController.searchBar.frame.height)
        
    }
    
    @IBAction func touchUpDateButton(_ sender: UIBarButtonItem) {

        if let datePickerConroller = DatePickerViewController.storyboardInstance() {
            
            if let year = dateParser.year(from: currentViewedDate) {
                let month : Int = dateParser.month(from: currentViewedDate)
                
                    datePickerConroller.selectedDate = (year, month)
                
                }
            
            datePickerConroller.modalPresentationStyle = .overCurrentContext
            present(datePickerConroller, animated: true, completion: nil)
            
        }
        
    }
}

extension DreamListViewController : UISearchBarDelegate {
    
    func searchBarSearchButtonClicked(_ searchBar: UISearchBar) {
        
        searchBar.resignFirstResponder()
        if let searchText = searchBar.text {
            filterContentForSearchText(searchText)
        }
        
    }
}

extension DreamListViewController : UISearchResultsUpdating {
    
    func updateSearchResults(for searchController: UISearchController) {
        filterContentForSearchText(searchController.searchBar.text!)
    }
    
    func searchBarIsEmpty() -> Bool {
        // Returns true if the text is empty or nil
        return searchController.searchBar.text?.isEmpty ?? true
    }
    
    
    
    func filterContentForSearchText(_ searchText: String, scope: String = "All") {
        
        guard isQueueEmpty else {
            return
        }
        
        concurrentQueue.async {
            self.isQueueEmpty = false

            DreamDataStore.shared.filter(searchText) {
                
                DispatchQueue.main.async {
                    self.tableView.reloadData()
                    self.isQueueEmpty = true
                }

            }
        }
    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
}

extension DreamListViewController : UITableViewDelegate, UITableViewDataSource, DreamDeletable {
    
    // MARK: - Table view dataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  self.isFiltering() ? DreamDataStore.shared.filteredDreams.count : DreamDataStore.shared.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "DreamListCell", for: indexPath) as? DreamListCell else {
            return UITableViewCell()
        }
        
        if isFiltering() {
            cell.update(dream: DreamDataStore.shared.filteredDreams[indexPath.row])
            
        } else {
            
            if let dream = DreamDataStore.shared.dream(at: indexPath.row) {
                cell.update(dream: dream)
            }
            
        }
        
        return cell
    }
    
    // MARK: - Table view delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let detailDreamViewController = DetailDreamViewController.storyboardInstance() {
            
            detailDreamViewController.dream = self.isFiltering() ? DreamDataStore.shared.filteredDreams[indexPath.row] : DreamDataStore.shared.dream(at: indexPath.row)
            navigationController?.pushViewController(detailDreamViewController, animated: true)
            
            if self.tableView.isEditing {
                detailDreamViewController.mode = .edit
            }
        }
    }

    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteButton = UITableViewRowAction(style: .destructive, title: "삭제") { action, indexPath -> Void in
            
            if let dream = DreamDataStore.shared.dream(at: indexPath.row) {
                let alert = self.deleteAlert(dream: dream, completion: nil)
                self.present(alert, animated: true, completion: nil)
            }
            
        }

        deleteButton.backgroundColor = UIColor.blue
        
        return [deleteButton]
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

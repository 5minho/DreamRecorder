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
    
    fileprivate let dateParser = DateParser()
    
    fileprivate let serialFilterQueue = DispatchQueue(label: DispatchQueueLabel.filterSerialQueue)
    fileprivate let serialSelectQueue = DispatchQueue(label: DispatchQueueLabel.selectSerialQueue)
    fileprivate var pendingFilterWorkItem: DispatchWorkItem?
    
    fileprivate var selectedCell: DreamListCell?
    fileprivate var selectedCellLabel: UILabel?
    
    var previewingContext : UIViewControllerPreviewing?
    
    var currentDatePeriod : (from: Date, to: Date) = {
        
        guard let from = DateParser().firstDayOfMonth(date: Date()) else {
            return (Date(), Date())
        }
        
        return (from, Date())
        
    }(){
        
        didSet {
            
            serialSelectQueue.async { [unowned self] in
                
                DreamDataStore.shared.select(period: self.currentDatePeriod)
                
                DispatchQueue.main.async { [unowned self] in
                    self.tableView.reloadData()
                }
                
            }
            
        }
        
    }
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        if traitCollection.forceTouchCapability == .available {
            previewingContext = registerForPreviewing(with: self, sourceView: tableView)
        }
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        tableView.rowHeight = UITableViewAutomaticDimension
        tableView.estimatedRowHeight = 140
        
        self.tableView.allowsSelectionDuringEditing = true
        self.dateButton.title = BarButtonText.date
        
        self.navigationItem.leftBarButtonItem = editButtonItem
        
        self.addObserver()
        self.setSearchViewController()
        self.applyThemeIfViewDidLoad()
        
    }
    
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.tableView.setEditing(false, animated: true)
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
    }
    
    override func setEditing(_ editing: Bool, animated: Bool) {
        
        super.setEditing(editing, animated: animated)
        self.tableView.setEditing(editing, animated: true)
        
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
        
        NotificationCenter.default.addObserver(forName: .DreamRecorderFontDidChange,
                                               object: nil,
                                               queue: .main) { [unowned self] _ in
            self.tableView.reloadData()
        }
        
        
        NotificationCenter.default.addObserver(forName: .DreamDataStoreDidDeleteDream, object: nil, queue: .main) {
            [unowned self] notification in
            
            if self.isFiltering() {
                
                if let row = notification.userInfo?[UserInfoKey.rowInFiltering] as? Int {
                    self.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
                }
                
            } else {
                
                if let row = notification.userInfo?[UserInfoKey.row] as? Int {
                    self.tableView.deleteRows(at: [IndexPath(row: row, section: 0)], with: .automatic)
                }
                
            }
            
        }
        
        NotificationCenter.default.addObserver(forName: .DreamDataStoreDidAddDream, object: nil, queue: .main) {
            [unowned self] notification in
            
            self.tableView.insertRows(at: [IndexPath(row: 0, section: 0)], with: .automatic)
        
        }
        
        NotificationCenter.default.addObserver(forName: .DreamDataStoreDidUpdateDream, object: nil, queue: .main) {
            [unowned self] notificataion in
        
            self.tableView.reloadData()
        
        }
        
    }
    
    func setEnabledNavigationButtons(enabled : Bool) {
    
        if let items = self.navigationItem.leftBarButtonItems {
            
            for button in items {
                button.isEnabled = enabled
            }
            
        }
        
        if let items = self.navigationItem.rightBarButtonItems {
            
            for button in items {
                button.isEnabled = enabled
            }
            
        }
        
    }
    
    private func setSearchViewController() {
        
        searchController = UISearchController(searchResultsController: nil)
        searchController?.searchResultsUpdater = self
        searchController?.dimsBackgroundDuringPresentation = false
        searchController?.searchBar.placeholder = DreamSearch.placeHolder
 
        definesPresentationContext = true
        searchController.delegate = self
        self.searchController.searchBar.delegate = self
        
        self.tableView?.tableHeaderView = searchController?.searchBar
        
        self.tableView.contentOffset =  CGPoint(x: 0, y: searchController.searchBar.frame.height)
        
    }
    
    @IBAction func touchUpDateButton(_ sender: UIBarButtonItem) {

        if let datePickerConroller = DatePickerViewController.storyboardInstance() {
            
            datePickerConroller.selectedPeriod = self.currentDatePeriod
            datePickerConroller.modalPresentationStyle = .overCurrentContext
            
            present(datePickerConroller, animated: true) { [unowned self] in
                self.setEnabledNavigationButtons(enabled: false)
            }
            
        }
    }
    
}

extension DreamListViewController : UISearchControllerDelegate {
    
    func didPresentSearchController(_ searchController: UISearchController) {
        
        if let context = previewingContext {
            unregisterForPreviewing(withContext: context)
            previewingContext = searchController.registerForPreviewing(with: self, sourceView: tableView)
        }
        
    }
    
    func didDismissSearchController(_ searchController: UISearchController) {
        
        if let context = previewingContext {
            searchController.unregisterForPreviewing(withContext: context)
            previewingContext = registerForPreviewing(with: self, sourceView: tableView)
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
    
    
    
    
    func filterContentForSearchText(_ searchText: String) {
        
        self.pendingFilterWorkItem?.cancel()
        
        let filterWorkItem = DispatchWorkItem {
            DreamDataStore.shared.filter(searchText)
            
            DispatchQueue.main.async { [unowned self] in
                self.tableView.reloadData()
            }
        }
        
        pendingFilterWorkItem = filterWorkItem
        
        serialFilterQueue.asyncAfter(deadline: .now() + .milliseconds(250), execute: filterWorkItem)

    }
    
    func isFiltering() -> Bool {
        return searchController.isActive && !searchBarIsEmpty()
    }
    
}

extension DreamListViewController : UITableViewDelegate, UITableViewDataSource, DreamDeletable {
    
    // MARK: - Table view dataSource
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return  self.isFiltering() ? DreamDataStore.shared.filteredDreams.count : DreamDataStore.shared.dreams.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.dreamListCell, for: indexPath) as? DreamListCell else {
            return UITableViewCell()
        }
        
        if isFiltering() {
            
            if let filterDream = DreamDataStore.shared.filteredDreams[safe: indexPath.row] {
                cell.update(dream: filterDream)
            }
        
        } else {
            
            if let dream = DreamDataStore.shared.dreams[safe: indexPath.row] {
                cell.update(dream: dream)
            }
            
        }
        
        return cell
    }
    
    
    // MARK: - Table view delegate
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if let detailDreamViewController = DetailDreamViewController.storyboardInstance() {
            
            detailDreamViewController.dream = self.isFiltering() ?
                DreamDataStore.shared.filteredDreams[safe: indexPath.row] :
                DreamDataStore.shared.dreams[safe: indexPath.row]
            
            navigationController?.pushViewController(detailDreamViewController, animated: true)
            
            if self.tableView.isEditing {
                detailDreamViewController.mode = .edit
            }
        }
    }

    
    func tableView(_ tableView: UITableView, editActionsForRowAt indexPath: IndexPath) -> [UITableViewRowAction]? {
        
        let deleteButton = UITableViewRowAction(style: .destructive, title: TableCellText.delete) { action, indexPath in
            
            if let dream = self.isFiltering() ?
                DreamDataStore.shared.filteredDreams[safe: indexPath.row] :
                DreamDataStore.shared.dreams[safe: indexPath.row] {
                
                let alert = self.deleteAlert(dream: dream, completion: nil)
                self.present(alert, animated: true, completion: nil)
                
            }
            
        }
        
        let shareButton = UITableViewRowAction(style: .normal, title: TableCellText.share) { action, indexPath in
            
            if let dream = self.isFiltering() ?
                DreamDataStore.shared.filteredDreams[safe: indexPath.row] :
                DreamDataStore.shared.dreams[safe: indexPath.row] {
                
                var title = "", content = ""
                
                if let dreamTitle = dream.title {
                    title = "꿈 제목: " + dreamTitle
                }
                
                if let dreamContent = dream.content {
                    content = "꿈 내용: " + dreamContent
                }
                
                let date = "꿈 저장일: " + self.dateParser.detail(from: dream.createdDate)
                
                let controller = UIActivityViewController(activityItems: [title, content, date], applicationActivities: nil)
                controller.excludedActivityTypes = [UIActivityType.message]
                
                self.present(controller, animated: true) {
                    self.tableView.setEditing(false, animated: true)
                }

            }
            
            
        }

        deleteButton.backgroundColor = UIColor.red
        shareButton.backgroundColor = UIColor.gray
        return [deleteButton, shareButton]
    }

    
}

extension DreamListViewController: DetailDreamViewControllerDelegate {
    
    func detailDreamViewController(_ controller: DetailDreamViewController, didActivePrewviewAction dream: Dream) {
        
    }
    
    func detailDreamViewController(_ controller: DetailDreamViewController, didDeletePrewviewAction dream: Dream) {
        
    }

    
}

extension DreamListViewController: UIViewControllerPreviewingDelegate {
    
    
    // MARK: - UIViewControllerPreviewingDelegate.
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        
        viewControllerToCommit.view.backgroundColor = UIColor.dreamBackgroundColor
        
        guard let detailDreamViewController = viewControllerToCommit as? DetailDreamViewController else {
            return
        }
        
        self.navigationController?.pushViewController(detailDreamViewController, animated: false)
        
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        
        let positionInView = self.view.convert(location, to: self.view)
        
        if let indexPath = self.tableView.indexPathForRow(at: positionInView) {
            
            let pickedDream = self.isFiltering() ? DreamDataStore.shared.filteredDreams[indexPath.row]: DreamDataStore.shared.dreams[indexPath.row]
            
            let cellRect = self.tableView.rectForRow(at: indexPath)
            previewingContext.sourceRect = cellRect
            
            guard let detailDreamViewController = DetailDreamViewController.storyboardInstance() else { return nil }
            
            detailDreamViewController.delegate = self
            detailDreamViewController.dream = pickedDream
            
            detailDreamViewController.view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            
            self.selectedCell = self.tableView.cellForRow(at: indexPath) as? DreamListCell
            self.selectedCellLabel = self.selectedCell?.dreamTitleLabel
            
            return detailDreamViewController
            
        } else {
            return nil
        }
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



//
//  AlarmListViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 8..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class AlarmListViewController: UIViewController {

    // MARK: - Properties.
    // - Subviews.
    @IBOutlet weak var tableView: UITableView!
    
    // - Private.
    fileprivate lazy var store: AlarmDataStore = AlarmDataStore.shared
    fileprivate let dateParser: DateParser = DateParser()
    /// default is true. it will set false to block reload table from AlarmDataStoreDidChange notification.
    /// UI(addController, editController, deleteAction)등을 통해 사용자 컨트롤로 일어나는 변화는 직접 해당 row만 변경을 위해
    /// AlarmDataStoreDidChange가 불려도 UITableView를 reload하지 않게 한다.
    fileprivate var shouldReloadTable: Bool = true
    
    /// Capture temporary selected cell and label for custom transitioning.
    fileprivate var selectedCell: AlarmListCell?
    fileprivate var selectedCellLabel: UILabel?
    
    // MARK: - Actions.
    // - NavigationItem.
    func leftBarButtonDidTap(sender: UIBarButtonItem) {
        self.tableView.setEditing(!self.tableView.isEditing, animated: true)
    }
    
    func rightBarButtonDidTap(sender: UIBarButtonItem) {
        guard let alarmAddViewController = AlarmAddViewController.storyboardInstance() else { return }
        let navigationController = UINavigationController(rootViewController: alarmAddViewController)
        
        alarmAddViewController.delegate = self
        alarmAddViewController.alarm = Alarm()
        
        self.present(navigationController, animated: true, completion: nil)
    }
    
    // MARK: - View Cycle.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.applyThemeIfViewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        
        self.tableView.estimatedRowHeight = 90
        self.tableView.allowsSelectionDuringEditing = true
        
        let leftBarButton = UIBarButtonItem(title: "Edit".localized,
                                            style: .plain,
                                            target: self,
                                            action: #selector(self.leftBarButtonDidTap(sender:)))
        let rightBarButton = UIBarButtonItem(barButtonSystemItem: .add,
                                             target: self,
                                             action: #selector(self.rightBarButtonDidTap(sender:)))
        self.navigationItem.setLeftBarButton(leftBarButton, animated: true)
        self.navigationItem.setRightBarButton(rightBarButton, animated: true)
        
        self.title = "Alarm".localized
        
        self.registerForPreviewing(with: self, sourceView: self.view)
        
        NotificationCenter.default.addObserver(self,
                                               selector: #selector(self.handleAlarmDataStoreDidChange),
                                               name: .AlarmDataStoreDidChange,
                                               object: nil)
        NotificationCenter.default.addObserver(forName: .UIContentSizeCategoryDidChange,
                                               object: nil,
                                               queue: OperationQueue.main)
        { _ in
            DispatchQueue.main.async {
                self.tableView.isHidden = true
                CustomFont.current.reloadFont()
                self.tableView.reloadData()
                self.tableView.isHidden = false
            }
        }
        
        NotificationCenter.default.addObserver(forName: Notification.Name.DreamRecorderFontDidChange,
                                               object: nil,
                                               queue: .main)
        { (_) in
            self.tableView.reloadData()
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        
        self.tableView.setEditing(false, animated: true)
    }
    
    // MARK: - Notification Handler.
    func handleAlarmDataStoreDidChange(sender: Notification){
        
        if self.shouldReloadTable {
            
            OperationQueue.main.addOperation {
                self.tableView.reloadSections(IndexSet(integer: .allZeros), with: .automatic)
            }
        }
        self.shouldReloadTable = true
    }
}

extension AlarmListViewController: UITableViewDelegate, UITableViewDataSource {
    // MARK: - TableView DataSource.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 1
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        return self.store.alarms.count
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        guard let cell = tableView.dequeueReusableCell(withIdentifier: "AlarmListCell",
                                                       for: indexPath) as? AlarmListCell
        else {
            return UITableViewCell()
        }
        
        let alarmForRow = self.store.alarms[indexPath.row]
        
        cell.timeLabel.text = self.dateParser.time(from: alarmForRow.date)
        cell.nameLabel.text = alarmForRow.name
        cell.activeSwitch.isOn = alarmForRow.isActive
        cell.weekdayButton.setSelection(options: alarmForRow.weekday)
        
        // AlarmListViewController에서는 Add, Edit페이지와는 다르게 weekdayButton에 접근할 필요가 없고
        // Cell을 설명해줄 때 weekdayButton내용도 포함해야한다.
        var customAccessibilityLabel = "\(cell.timeLabel.text ?? ""),"
        customAccessibilityLabel += "\(cell.nameLabel.text ?? ""),"
        customAccessibilityLabel += "\(cell.weekdayButton.accessibilityLabel ?? "")"
        cell.accessibilityLabel = customAccessibilityLabel
        
        cell.delegate = self
        cell.activeSwitch.tag = indexPath.row
        cell.weekdayButton.setButtonsEnabled(to: false)
        
        // Update Font If ContentSizeCategoryDidChange
        cell.timeLabel.font = UIFont.title1
        cell.nameLabel.font = UIFont.body
        cell.weekdayButton.setFonts(to: UIFont.caption1)
        
        return cell
    }
    
    // MARK: - TableView Delegate.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        tableView.deselectRow(at: indexPath, animated: true)
        
        if self.tableView.isEditing {
            // UITableView isEditing.
            guard let alarmEditViewController = AlarmEditViewController.storyboardInstance() else { return }
            
            alarmEditViewController.alarm = self.store.alarms[indexPath.row]
            alarmEditViewController.delegate = self
            
            let navigationController = UINavigationController(rootViewController: alarmEditViewController)
            
            self.present(navigationController, animated: true, completion: nil)
            
        } else {
            // UITableView not isEditing.
            guard let cell = tableView.cellForRow(at: indexPath) as? AlarmListCell else { return }
            
            self.selectedCell = cell
            self.selectedCellLabel = cell.timeLabel
            
            let selectedAlarm = self.store.alarms[indexPath.row]
            
            if selectedAlarm.isActive == false {
                
                let alertController = UIAlertController(title: "Alarm".localized,
                                                        message: "This alarm is not active.".localized,
                                                        preferredStyle: .alert)
                
                let okAction = UIAlertAction(title: "OK".localized,
                                             style: .default)
                {
                    (action) in
                    alertController.dismiss(animated: true, completion: nil)
                }
                
                alertController.addAction(okAction)
                
                self.present(alertController, animated: true, completion: nil)
                
            } else {
                
                guard let alarmPlayViewController = AlarmStateViewController.storyboardInstance() else { return }
                
                alarmPlayViewController.presentingDelegate = self
                alarmPlayViewController.currentAlarm = selectedAlarm
                
                self.present(alarmPlayViewController, animated: true, completion: nil)
            }
        }
    }
    
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            self.shouldReloadTable = false
            
            let deletingAlarm = self.store.alarms[indexPath.row]
            
            self.store.deleteAlarm(alarm: deletingAlarm)
            
            // Replace reload table with deleting rows if alarm deleted.
            self.tableView.deleteRows(at: [indexPath], with: .automatic)
        }
    }
    
}
extension AlarmListViewController: AlarmListCellDelegate {
    // MARK: - AlarmListCell Delegate.
    func alarmListCell(cell : AlarmListCell, activeSwitchValueChanged sender: UISwitch) {
        
        guard sender.tag < self.store.alarms.count else { return }
        
        let updatingAlarm = self.store.alarms[sender.tag]
        updatingAlarm.isActive = sender.isOn
        
        self.shouldReloadTable = false
        
        self.store.updateAlarm(alarm: updatingAlarm)
        
        let updatedIndexPath = IndexPath(row: sender.tag, section: 0)
        self.tableView.reloadRows(at: [updatedIndexPath], with: .automatic)
    }
}

extension AlarmListViewController: AlarmAddViewControllerDelegate, AlarmEditViewControllerDelegate {
    // MARK: - AlarmAddViewController Delegate.
    func alarmAddViewController(_: AlarmAddViewController, didSaveNewAlarm alarm: Alarm) {
        
        self.shouldReloadTable = false
        
        alarm.date = alarm.date.removingSeconds()
        self.store.insertAlarm(alarm: alarm)
        
        // Replace reload table with inserting rows if alarm added.
        guard let index = self.store.alarms.index(of: alarm) else { return }
        let newIndexPath = IndexPath(row: index, section: 0)
        
        self.tableView.insertRows(at: [newIndexPath], with: .automatic)
    }
    
    // MARK: - AlarmEditViewController Delegate.
    func alarmEditViewController(_ controller: AlarmEditViewController, didSaveEditedAlarm alarm: Alarm) {
        
        self.shouldReloadTable = false

        alarm.date = alarm.date.removingSeconds()
        
        if alarm.isActive == false {
            
            let alertController = UIAlertController(title: "Alarm".localized,
                                                    message: "Do you want to activate this alarm?".localized,
                                                    preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK".localized,
                                         style: .default)
            { (action) in
                
                alarm.isActive = true
                
                self.store.updateAlarm(alarm: alarm)

                // Replace reload table with reloading rows if alarm updated.
                guard let index = self.store.alarms.index(of: alarm) else { return }
                let editedIndexPath = IndexPath(row: index, section: 0)
                
                self.tableView.reloadRows(at: [editedIndexPath], with: .automatic)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel".localized,
                                             style: .cancel)
            { (action) in
                
                self.store.updateAlarm(alarm: alarm)
                
                // Replace reload table with reloading rows if alarm updated.
                guard let index = self.store.alarms.index(of: alarm) else { return }
                let editedIndexPath = IndexPath(row: index, section: 0)
                
                self.tableView.reloadRows(at: [editedIndexPath], with: .automatic)
            }
            
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        } else {
            
            self.store.updateAlarm(alarm: alarm)
            
            // Replace reload table with reloading rows if alarm updated.
            guard let index = self.store.alarms.index(of: alarm) else { return }
            let editedIndexPath = IndexPath(row: index, section: 0)
            
            self.tableView.reloadRows(at: [editedIndexPath], with: .automatic)
        }
    }
}

extension AlarmListViewController: AlarmStateViewControllerDelegate {
    // MARK: - AlarmStateViewController Delegate.
    func alarmStateViewController(_ controller: AlarmStateViewController, didActivePrewviewAction alarm: Alarm) {
        
        guard let activatedRow = self.store.alarms.index(of: alarm) else { return }
        
        alarm.isActive = true
        
        self.shouldReloadTable = false
        
        self.store.updateAlarm(alarm: alarm)
        
        let activatedIndexPath = IndexPath(row: activatedRow, section: 0)
        self.tableView.reloadRows(at: [activatedIndexPath], with: .automatic)
    }
    
    func alarmStateViewController(_ controller: AlarmStateViewController, didDeletePrewviewAction alarm: Alarm) {
        
        guard let deletedRow = self.store.alarms.index(of: alarm) else { return }
        
        alarm.isActive = true
        
        self.shouldReloadTable = false
        
        self.store.deleteAlarm(alarm: alarm)
        
        let deletedIndexPath = IndexPath(row: deletedRow, section: 0)
        self.tableView.deleteRows(at: [deletedIndexPath], with: .automatic)
    }
}

extension AlarmListViewController: UIViewControllerPreviewingDelegate {
    // MARK: - UIViewControllerPreviewingDelegate.
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let alarmStateViewController = viewControllerToCommit as? AlarmStateViewController else { return }
        guard let isActiveAlarm = alarmStateViewController.currentAlarm?.isActive else { return }
        if isActiveAlarm {
            alarmStateViewController.view.backgroundColor = UIColor.dreamBackgroundColor
            self.present(alarmStateViewController, animated: true, completion: nil)
        }
    }
    
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, viewControllerForLocation location: CGPoint) -> UIViewController? {
        let positionInView = self.view.convert(location, to: self.tableView)
        
        if let indexPath = self.tableView.indexPathForRow(at: positionInView) {
            let pickedAlarm = AlarmDataStore.shared.alarms[indexPath.row]
            let cellRect = self.tableView.rectForRow(at: indexPath)
            previewingContext.sourceRect = cellRect
            
            guard let alarmStateViewController = AlarmStateViewController.storyboardInstance() else { return nil }
            
            alarmStateViewController.delegate = self
            alarmStateViewController.presentingDelegate = self
            alarmStateViewController.currentAlarm = pickedAlarm
            
            alarmStateViewController.view.backgroundColor = UIColor.white.withAlphaComponent(0.3)
            
            self.selectedCell = self.tableView.cellForRow(at: indexPath) as? AlarmListCell
            self.selectedCellLabel = self.selectedCell?.timeLabel
            
            return alarmStateViewController
            
        } else {
            return nil
        }
    }
    
}

extension AlarmListViewController: ThemeAppliable {
    // MARK: - ThemeAppliable.
    var themeStyle: ThemeStyle {
        return .alarm
    }
    var themeTableView: UITableView? {
        return self.tableView
    }
}

extension AlarmListViewController: CellExpandAnimatorPresentingDelegate {
    // MARK: - CellExpandAnimatorPresentingDelegate.
    var presentingView: UIView {
        return self.selectedCell ?? self.view
    }
    var presentingLabel: UILabel {
        return self.selectedCellLabel ?? UILabel()
    }
}

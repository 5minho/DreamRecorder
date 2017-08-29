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
    fileprivate var store: AlarmDataStore {
        return AlarmDataStore.shared
    }
    fileprivate let dateParser: DateParser = DateParser()
    /// 기본값은 True이다. AlarmDataStoreDidChange의 노티피케이션을 받았을 때 UITableView를 리로드하고 싶지 않을 때 false로 설정될 수 있다.
    ///
    /// 콘트롤러를 통해 add, edit을 하거나 action을 통해 delete하게 되는 경우에는 스스로 index를 찾아서 데이터를 추가, 수정, 삭제하기 때문에
    /// 굳이 AlarmDataStore에서 변경을 마치고 알려주는 DidChange를 통해 다시 리로드 할 필요없다는 것을 명시적으로 알려준다.
    fileprivate var shouldReloadTable: Bool = true
    
    /// 선택된 셀과 셀의 레이블을 커스텀 애니메이션을 위해 프로퍼티로 잡고 있는다.
    fileprivate var selectedCell: AlarmListCell?
    fileprivate var selectedCellLabel: UILabel?
    
    // MARK: - Actions.
    // - NavigationItem.
    /// 알람 편집 버튼 클릭.
    func leftBarButtonDidTap(sender: UIBarButtonItem) {
        self.tableView.setEditing(!self.tableView.isEditing, animated: true)
    }
    
    /// 알람 추가 버튼 클릭.
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
        
        /// UITableViewCell에 Pick & Pop을 구현하기위헤 Previewing을 등록한다.
        self.registerForPreviewing(with: self, sourceView: self.view)
        
        /// 알람에 변경이 되었을 때 테이블뷰를 업데이트하기위해 노티피케이션을 구독한다.
        NotificationCenter.default.addObserver(forName: .AlarmDataStoreDidChange,
                                               object: nil,
                                               queue: .main)
        { (_) in
            /// AlarmListViewController가 알고 있지 않은 변화가 생겼을 때는 UITableView를 리로드한다.
            if self.shouldReloadTable {
                OperationQueue.main.addOperation {
                    self.tableView.reloadSections(IndexSet(integer: .allZeros), with: .automatic)
                }
            }
            /// AlarmListViewController가 알고 있는 변화의 경우 호출되더라도 이후에는 다시 호출될 수 있으므로 shouldReloadTable을 true로 변경한다.
            self.shouldReloadTable = true
        }
        
        /// DreamRecorder 설정페이지 에서 제공하는 폰트를 변경 노티피케이션을 구독한다.
        NotificationCenter.default.addObserver(forName: .DreamRecorderFontDidChange,
                                               object: nil,
                                               queue: .main)
        { (_) in
            /// 폰트가 바뀌었을 때 테이블뷰를 리로드한다.
            self.tableView.reloadData()
        }
        
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        /// 편집모드중에 탭이동, 추가버튼을 눌렀을 때는 편집모드를 종료한다.
        self.tableView.setEditing(false, animated: true)
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
        
        /// AlarmListViewController에서는 Add, Edit페이지와는 다르게 weekdayButton에 접근할 필요가 없고
        /// Cell을 설명해줄 때 weekdayButton내용(반복 요일)도 포함해야한다.
        
        var customAccessibilityLabel = "\(alarmForRow.date.dateForAlarm.descriptionForAlarmTime ?? ""),"
        customAccessibilityLabel += "\(cell.nameLabel.text ?? ""),"
        customAccessibilityLabel += "\(cell.weekdayButton.accessibilityLabel ?? "")"
        cell.accessibilityLabel = customAccessibilityLabel
        
        cell.delegate = self
        cell.activeSwitch.tag = indexPath.row
        cell.weekdayButton.setButtonsEnabled(to: false)
        
        /// Larger Font가 바뀌었을 경우를 대비해야 테이블뷰가 리로드 할때마다 폰트를 적용할 수 있게 한다.
        cell.timeLabel.font = UIFont.title1
        cell.nameLabel.font = UIFont.body
        cell.weekdayButton.setFonts(to: UIFont.caption1)
        
        return cell
    }
    
    // MARK: - TableView Delegate.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
    
        tableView.deselectRow(at: indexPath, animated: true)
        
        if self.tableView.isEditing {
            /// 알람 편집 모드.
            /// 알람을 수정할 수 있는 AlarmEditViewController를 띄운다.
            guard let alarmEditViewController = AlarmEditViewController.storyboardInstance() else { return }
            
            alarmEditViewController.alarm = self.store.alarms[indexPath.row]
            alarmEditViewController.delegate = self
            
            let navigationController = UINavigationController(rootViewController: alarmEditViewController)
            
            self.present(navigationController, animated: true, completion: nil)
            
        } else {
            /// 알람 일반 모드.
            /// 알람의 상태정보를 보여주는 창을 띄운다.
            ///
            /// 만약 해당 알람이 isActive가 false인 경우에는 알람을 활성화가 필요하다는 것을 알린다.
            guard let cell = tableView.cellForRow(at: indexPath) as? AlarmListCell else { return }
            
            self.selectedCell = cell
            self.selectedCellLabel = cell.timeLabel
            
            let selectedAlarm = self.store.alarms[indexPath.row]
            
            /// 알람이 비활성화 된 경우는 경고창을 띄운다.
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
                
            /// 알람이 활성회 된 경우 AlarmStateViewController를 띄운다.
            } else {
                
                guard let alarmStateViewController = AlarmStateViewController.storyboardInstance() else { return }
                
                alarmStateViewController.presentingDelegate = self
                alarmStateViewController.currentAlarm = selectedAlarm
                
                self.present(alarmStateViewController, animated: true, completion: nil)
            }
        }
    }
    
    /// 알람을 셀을 Swipe함으로써 제거 가능하도록 한다.
    func tableView(_ tableView: UITableView, commit editingStyle: UITableViewCellEditingStyle, forRowAt indexPath: IndexPath) {
        
        if editingStyle == .delete {
            
            /// AlarmDataStore가 작업 후에 불리는 노티피케이션에 의해 테이블뷰가 리로드 되는 것을 방지한다.
            self.shouldReloadTable = false
            
            let deletingAlarm = self.store.alarms[indexPath.row]
            
            self.store.deleteAlarm(alarm: deletingAlarm)
            
            /// shouldReloadTable을 false하였기때문에 명시적으로 자신이 deleteRows를 해주어야한다.
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
        
        /// AlarmDataStore가 작업 후에 불리는 노티피케이션에 의해 테이블뷰가 리로드 되는 것을 방지한다.
        self.shouldReloadTable = false
        
        self.store.updateAlarm(alarm: updatingAlarm)
        
        /// shouldReloadTable을 false하였기때문에 명시적으로 자신이 updateRows를 해주어야한다.
        let updatedIndexPath = IndexPath(row: sender.tag, section: 0)
        self.tableView.reloadRows(at: [updatedIndexPath], with: .automatic)
    }
}

extension AlarmListViewController: AlarmAddViewControllerDelegate, AlarmEditViewControllerDelegate {
    // MARK: - AlarmAddViewController Delegate.
    func alarmAddViewController(_: AlarmAddViewController, didSaveNewAlarm alarm: Alarm) {
        /// AlarmDataStore가 작업 후에 불리는 노티피케이션에 의해 테이블뷰가 리로드 되는 것을 방지한다.
        self.shouldReloadTable = false
        
        /// 알람 시간이 변경될 수 있는 경우에는 알람 시간에서 초는 항상 제거한다.
        alarm.date = alarm.date.dateForAlarm.removingSeconds
        self.store.insertAlarm(alarm: alarm)
        
        /// shouldReloadTable을 false하였기때문에 명시적으로 자신이 insertRows를 해주어야한다.
        guard let index = self.store.alarms.index(of: alarm) else { return }
        let newIndexPath = IndexPath(row: index, section: 0)
        self.tableView.insertRows(at: [newIndexPath], with: .automatic)
    }
    
    // MARK: - AlarmEditViewController Delegate.
    func alarmEditViewController(_ controller: AlarmEditViewController, didSaveEditedAlarm alarm: Alarm) {
        /// AlarmDataStore가 작업 후에 불리는 노티피케이션에 의해 테이블뷰가 리로드 되는 것을 방지한다.
        self.shouldReloadTable = false
        
        /// 알람 시간이 변경될 수 있는 경우에는 알람 시간에서 초는 항상 제거한다.
        alarm.date = alarm.date.dateForAlarm.removingSeconds
        
        if alarm.isActive == false {
            
            let alertController = UIAlertController(title: "Alarm".localized,
                                                    message: "Do you want to activate this alarm?".localized,
                                                    preferredStyle: .alert)
            
            let okAction = UIAlertAction(title: "OK".localized,
                                         style: .default)
            { (action) in
                
                alarm.isActive = true
                
                self.store.updateAlarm(alarm: alarm)

                /// shouldReloadTable을 false하였기때문에 명시적으로 자신이 updateRows를 해주어야한다.
                guard let index = self.store.alarms.index(of: alarm) else { return }
                let editedIndexPath = IndexPath(row: index, section: 0)
                
                self.tableView.reloadRows(at: [editedIndexPath], with: .automatic)
            }
            
            let cancelAction = UIAlertAction(title: "Cancel".localized,
                                             style: .cancel)
            { (action) in
                
                self.store.updateAlarm(alarm: alarm)
                
                /// shouldReloadTable을 false하였기때문에 명시적으로 자신이 updateRows를 해주어야한다.
                guard let index = self.store.alarms.index(of: alarm) else { return }
                let editedIndexPath = IndexPath(row: index, section: 0)
                
                self.tableView.reloadRows(at: [editedIndexPath], with: .automatic)
            }
            
            alertController.addAction(okAction)
            alertController.addAction(cancelAction)
            
            self.present(alertController, animated: true, completion: nil)
            
        } else {
            
            self.store.updateAlarm(alarm: alarm)
            
            /// shouldReloadTable을 false하였기때문에 명시적으로 자신이 updateRows를 해주어야한다.
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
        
        /// 알람을 활성화 시키기 위해 객체 프로퍼티를 변경한다.
        alarm.isActive = true
        
        /// AlarmDataStore가 작업 후에 불리는 노티피케이션에 의해 테이블뷰가 리로드 되는 것을 방지한다.
        self.shouldReloadTable = false
        
        /// AlarmDataStore에 접근하여 변경된 알람을 수정한다.
        self.store.updateAlarm(alarm: alarm)
        
        /// shouldReloadTable을 false하였기때문에 명시적으로 자신이 updateRows를 해주어야한다.
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
    /// Pick된 알람이 활성화가 되어 있을 경우에는 AlarmStateViewController를 띄운다.
    func previewingContext(_ previewingContext: UIViewControllerPreviewing, commit viewControllerToCommit: UIViewController) {
        guard let alarmStateViewController = viewControllerToCommit as? AlarmStateViewController else { return }
        guard let isActiveAlarm = alarmStateViewController.currentAlarm?.isActive else { return }
        if isActiveAlarm {
            alarmStateViewController.view.backgroundColor = UIColor.dreamBackgroundColor
            self.present(alarmStateViewController, animated: true, completion: nil)
        }
    }
    
    /// Pick되었을 때 보여줄 AlarmStateViewController를 생성한다.
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

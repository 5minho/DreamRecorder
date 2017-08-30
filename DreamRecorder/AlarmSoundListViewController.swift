//
//  AlarmSoundListViewController.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 16..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit
import MediaPlayer

protocol AlarmSoundListViewControllerDelegate: NSObjectProtocol {
    func alarmSoundListViewController(_ controller: AlarmSoundListViewController, didChangeSoundName: String)
}

class AlarmSoundListViewController: UIViewController {
    
    // MARK: - Properties.
    // Subviews.
    @IBOutlet weak var tableView: UITableView!
    
    // Internal.
    var alarm: Alarm?
    weak var delegate: AlarmSoundListViewControllerDelegate?
    
    // Private.
    fileprivate let soundNames: [String] = [SoundFileName.defaultSound,
                                            SoundFileName.alarmTone,
                                            SoundFileName.oldAlarm,
                                            SoundFileName.carefreeMelody]
    
    // MARK: - View Cycle.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.applyThemeIfViewDidLoad()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
        self.tableView.estimatedRowHeight = 44
        
        self.title = NavigationTitle.sound
    }
}

extension AlarmSoundListViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: - TableView DataSource.
    func numberOfSections(in tableView: UITableView) -> Int {
        return 2
    }
    
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        if section == 0 {
            return self.soundNames.count
        } else {
            return 1
        }
    }
    
    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        
        let cell = tableView.dequeueReusableCell(withIdentifier: Identifier.uitableViewCell, for: indexPath)
        
        guard let editingAlarm = self.alarm else { return cell }
        
        if indexPath.section == 0 {
            
            cell.textLabel?.textColor = UIColor.dreamTextColor1
            cell.textLabel?.text = soundNames[indexPath.row].soundTitle
            cell.accessoryType = (editingAlarm.sound == self.soundNames[indexPath.row]) ? .checkmark : .none
            
            return cell
            
        } else {
            
            cell.textLabel?.text = GuideText.pickSong
            cell.textLabel?.textColor = UIColor.dreamTextColor3
            cell.detailTextLabel?.textColor = UIColor.dreamTextColor1
            
            if self.soundNames.contains(editingAlarm.sound) == false {
                
                cell.accessoryType = .checkmark
                cell.detailTextLabel?.text = self.alarm?.sound.soundTitle
                
            } else {
                cell.accessoryType = .none
            }
            
            return cell
        }
    }
    
    // MARK: - TableView Delegate.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            /// Bundle Sound Files.
            for cell in tableView.visibleCells {
                cell.accessoryType = .none
            }
            
            let selectedCell = tableView.cellForRow(at: indexPath)
            selectedCell?.accessoryType = .checkmark
            
            let selectedSoundName = self.soundNames[indexPath.row]
            self.alarm?.sound = selectedSoundName
            
            self.delegate?.alarmSoundListViewController(self, didChangeSoundName: selectedSoundName)
            self.navigationController?.popViewController(animated: true)
            
        } else {
            /// Select Media Library Music Files.
            let mediaPickerController = MPMediaPickerController(mediaTypes: .any)
            mediaPickerController.allowsPickingMultipleItems = false
            mediaPickerController.showsCloudItems = false
            mediaPickerController.delegate = self
            
            self.present(mediaPickerController, animated: true, completion: nil)
        }
    }
}

extension AlarmSoundListViewController: MPMediaPickerControllerDelegate {
    // MARK: - MPMediaPickerController Delegate.
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        if let item = mediaItemCollection.items.first,
            let itemURL = item.assetURL {
            
            self.alarm?.sound = itemURL.absoluteString
            
            mediaPicker.dismiss(animated: true, completion: {
                self.delegate?.alarmSoundListViewController(self, didChangeSoundName: itemURL.absoluteString)
                self.navigationController?.popViewController(animated: true)
            })
        } else {
            self.navigationController?.popViewController(animated: true)
        }
    }
}

extension AlarmSoundListViewController: ThemeAppliable {
    // MARK: - ThemeAppliable.
    var themeStyle: ThemeStyle {
        return .alarm
    }
    var themeTableView: UITableView? {
        return self.tableView
    }
}

extension AlarmSoundListViewController {
    // MARK: - StoryboardInstance.
    class func storyboardInstance() -> AlarmSoundListViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmSoundListViewController
    }
}

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
    
    // MARK: Properties.
    // Subviews.
    @IBOutlet weak var tableView: UITableView!
    
    // Internal.
    var alarm: Alarm?
    weak var delegate: AlarmSoundListViewControllerDelegate?
    
    // Private.
    fileprivate var soundNames: [String] = ["Default.wav", "Alarm-tone.wav", "Old-alarm-clock-ringing.wav", "Carefree_Melody.mp3"]
    
    // Mark: View Cycle.
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.applyTheme()
        
        self.tableView.delegate = self
        self.tableView.dataSource = self
    }
}

extension AlarmSoundListViewController: UITableViewDataSource, UITableViewDelegate {
    
    // MARK: TableView DataSource.
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
        
        let cell = tableView.dequeueReusableCell(withIdentifier: "UITableViewCell", for: indexPath)
        guard let editingAlarm = self.alarm else { return cell }
        
        cell.textLabel?.font = UIFont.title3
        cell.backgroundColor = UIColor.alarmDefaultBackgroundColor
        cell.textLabel?.textColor = UIColor.alarmDarkText
        cell.tintColor = UIColor.alarmSwitchOnTintColor
        if indexPath.section == 0 {
            cell.textLabel?.text = soundNames[indexPath.row].soundTitle
            cell.accessoryType = (editingAlarm.sound == self.soundNames[indexPath.row]) ? .checkmark : .none
            return cell
        } else {
            cell.textLabel?.text = "Custom"
            cell.detailTextLabel?.font = UIFont.caption
            cell.detailTextLabel?.textColor = UIColor.alarmLightText
            if self.soundNames.contains(editingAlarm.sound) == false {
                cell.accessoryType = .checkmark
                cell.detailTextLabel?.text = self.alarm?.sound.soundTitle
            } else {
                cell.accessoryType = .none
            }
            return cell
        }
    }
    
    // MARK: TableView Delegate.
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        
        tableView.deselectRow(at: indexPath, animated: true)
        
        if indexPath.section == 0 {
            // Bundle Sound Files.
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
            // Media Library Music Files.
            let pickerController = MPMediaPickerController(mediaTypes: .any)
            pickerController.delegate = self
            pickerController.allowsPickingMultipleItems = false
            pickerController.showsCloudItems = false
            self.present(pickerController, animated: true, completion: nil)
        }
    }
}

extension AlarmSoundListViewController: MPMediaPickerControllerDelegate {
    // MARK: MPMediaPickerController Delegate.
    func mediaPickerDidCancel(_ mediaPicker: MPMediaPickerController) {
        mediaPicker.dismiss(animated: true, completion: nil)
    }
    
    func mediaPicker(_ mediaPicker: MPMediaPickerController, didPickMediaItems mediaItemCollection: MPMediaItemCollection) {
        
        guard let item = mediaItemCollection.items.first else { return }
        guard let itemURL = item.assetURL else { return }
        
        self.alarm?.sound = itemURL.absoluteString
        mediaPicker.dismiss(animated: true, completion: {
            self.delegate?.alarmSoundListViewController(self, didChangeSoundName: itemURL.absoluteString)
            self.navigationController?.popViewController(animated: true)
        })
    }
}

extension AlarmSoundListViewController: ThemeAppliable {
    // MARK: ThemeAppliable
    var themeStyle: ThemeStyle {
        return .alarm
    }
    var themeTableView: UITableView? {
        return self.tableView
    }
    var themeNavigationController: UINavigationController? {
        return self.navigationController
    }
}

extension AlarmSoundListViewController {
    // MARK: StoryboardInstance.
    class func storyboardInstance() -> AlarmSoundListViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? AlarmSoundListViewController
    }
}

//
//  DatePickerViewController.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 21..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class DatePickerViewController : UIViewController {
    
    static func storyboardInstance() -> DatePickerViewController? {
        
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? DatePickerViewController
        
    }
    
    @IBOutlet weak var fromDatePicker: UIDatePicker!
    @IBOutlet weak var toDatePicker: UIDatePicker!
    
    @IBOutlet weak var descriptionLabel: UILabel!
    
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    
    var selectedPeriod : (from: Date, to: Date) = (Date(), Date())
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        self.applyThemeIfViewDidLoad()
        setDatePickers()
        setDescriptionLabel()
        setButtonsLabel()
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        
        self.fromDatePicker.setDate(self.selectedPeriod.from, animated: false)
        self.toDatePicker.setDate(self.selectedPeriod.to, animated: false)
        
    }
    
    private func setDatePickers() {
        
        self.fromDatePicker.setValue(UIColor.dreamTextColor1, forKey: Key.datePickerTextColor)
        self.toDatePicker.setValue(UIColor.dreamTextColor1, forKey: Key.datePickerTextColor)
        
        self.fromDatePicker.minimumDate = DreamDataStore.shared.minimumDate()
        self.fromDatePicker.maximumDate = DreamDataStore.shared.maximumDate()
        
        self.toDatePicker.minimumDate = DreamDataStore.shared.minimumDate()
        self.toDatePicker.maximumDate = DreamDataStore.shared.maximumDate()
        
    }
    
    private func setDescriptionLabel() {
        self.descriptionLabel.textColor = UIColor.dreamTextColor1
    }
    
    private func setButtonsLabel() {
        
        self.cancelButton.backgroundColor = UIColor.dreamBackgroundColor
        self.okButton.backgroundColor = UIColor.dreamBackgroundColor
        
    }
    
    @IBAction func fromDateChanged(_ sender: UIDatePicker) {
        self.selectedPeriod.from = sender.date
    }

    
    @IBAction func toDateChanged(_ sender: UIDatePicker) {
        self.selectedPeriod.to = sender.date
    }
    
    
    @IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func touchUpCancelButton(_ sender: UIButton) {
        
        weak var dreamListViewController = self.presentingViewController as? DreamListViewController
        dreamListViewController?.setEditing(false, animated: false)
        dreamListViewController?.setEnabledNavigationButtons(enabled: true)
        self.presentingViewController?.dismiss(animated: true)
        
    }
    
    @IBAction func touchUpOkButton(_ sender: UIButton) {
        
        if selectedPeriod.from > selectedPeriod.to {
            selectedPeriod = (selectedPeriod.to, selectedPeriod.from)
        }
        
        weak var dreamListViewController = self.presentingViewController as? DreamListViewController
        dreamListViewController?.currentDatePeriod = self.selectedPeriod
        
        dreamListViewController?.setEditing(false, animated: false)
        dreamListViewController?.setEnabledNavigationButtons(enabled: true)
        self.presentingViewController?.dismiss(animated: true)
        
    }
    
}

extension DatePickerViewController : ThemeAppliable {
    
    var themeStyle: ThemeStyle {
        return .dream
    }
    
    var themeTableView: UITableView? {
        return nil
    }
    
    var themeNavigationController: UINavigationController? {
        return self.navigationController
    }
}

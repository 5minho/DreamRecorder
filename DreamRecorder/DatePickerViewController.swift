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
    
    enum DateType : Int {
        
        case year = 0
        case month

    }
    
    @IBOutlet weak var datePicker: UIPickerView!
    @IBOutlet weak var cancelButton: UIButton!
    @IBOutlet weak var okButton: UIButton!
    
    var selectedDate : (year: Int?, month: Int?)?
    let currentYear = DateParser().year(from: Date())
    
    lazy var years: [Int] = {
        
        var years : [Int] = []
        
        if var currentYear = self.currentYear {
            for _ in 1 ... 30 {
                years.append(currentYear)
                currentYear -= 1
            }
        }
        
        return years
        
    }()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        self.cancelButton.translatesAutoresizingMaskIntoConstraints = false
        self.okButton.translatesAutoresizingMaskIntoConstraints = false
        self.datePicker.translatesAutoresizingMaskIntoConstraints = false
        
        self.setSubViewsBackGroundColor()
        
        self.view.addConstraints(cancelButtonConstraints())
        self.view.addConstraints(okButtonConstraints())
        self.view.addConstraints(datePickerConstraints())
        
        self.datePicker.delegate = self
        self.datePicker.dataSource = self
        
        if let year = self.selectedDate?.year, let month = self.selectedDate?.month, let currentYear = self.currentYear{
            
            self.datePicker.selectRow(currentYear - year, inComponent: DateType.year.rawValue, animated: false)
            self.datePicker.selectRow(month - 1, inComponent: DateType.month.rawValue, animated: false)
            
        }
        
        view.backgroundColor = UIColor.clear.withAlphaComponent(0.5)
        view.isOpaque = false
        
    }
    
    private func setSubViewsBackGroundColor() {
        
        self.cancelButton.backgroundColor = UIColor.dreamDarkPink
        self.okButton.backgroundColor = UIColor.dreamDarkPink
        self.datePicker.backgroundColor = UIColor.dreamPink
        
    }
    
    private func cancelButtonConstraints() -> [NSLayoutConstraint] {
        
        let height = NSLayoutConstraint(item: self.cancelButton,
                                        attribute: .height,
                                        relatedBy: .equal,
                                        toItem: self.datePicker,
                                        attribute: .height,
                                        multiplier: 0.25,
                                        constant: 0)
        
        let leading = NSLayoutConstraint(item: self.cancelButton,
                                         attribute: .leading,
                                         relatedBy: .equal,
                                         toItem: self.datePicker,
                                         attribute: .leading,
                                         multiplier: 1,
                                         constant: 0)
        
        let width = NSLayoutConstraint(item: self.cancelButton,
                                       attribute: .width,
                                       relatedBy: .equal,
                                       toItem: self.datePicker,
                                       attribute: .width,
                                       multiplier: 0.5,
                                       constant: 0)
        
        let bottom = NSLayoutConstraint(item: self.cancelButton,
                                        attribute: .bottom,
                                        relatedBy: .equal,
                                        toItem: self.view,
                                        attribute: .bottom,
                                        multiplier: 1,
                                        constant: 0)
        
        return [height, leading, width, bottom]
        
    }
    
    private func okButtonConstraints() -> [NSLayoutConstraint] {
        
        let top = NSLayoutConstraint(item: self.okButton,
                                        attribute: .top,
                                        relatedBy: .equal,
                                        toItem: self.cancelButton,
                                        attribute: .top,
                                        multiplier: 1,
                                        constant: 0)
        
        let leading = NSLayoutConstraint(item: self.okButton,
                                         attribute: .leading,
                                         relatedBy: .equal,
                                         toItem: self.cancelButton,
                                         attribute: .trailing,
                                         multiplier: 1,
                                         constant: 0)
        
        let bottom = NSLayoutConstraint(item: self.okButton,
                                       attribute: .bottom,
                                       relatedBy: .equal,
                                       toItem: self.cancelButton,
                                       attribute: .bottom,
                                       multiplier: 1,
                                       constant: 0)
        
        let trailing = NSLayoutConstraint(item: self.okButton,
                                        attribute: .trailing,
                                        relatedBy: .equal,
                                        toItem: self.datePicker,
                                        attribute: .trailing,
                                        multiplier: 1,
                                        constant: 0)
        
        return [top, leading, bottom, trailing]
        
    }

    private func datePickerConstraints() -> [NSLayoutConstraint] {
        
        let height = NSLayoutConstraint(item: self.datePicker,
                                        attribute: .height,
                                        relatedBy: .equal,
                                        toItem: self.view,
                                        attribute: .height,
                                        multiplier: 0.5,
                                        constant: 0)
        
        let leading = NSLayoutConstraint(item: self.datePicker,
                                         attribute: .leading,
                                         relatedBy: .equal,
                                         toItem: self.view,
                                         attribute: .leading,
                                         multiplier: 1,
                                         constant: 0)
        
        let width = NSLayoutConstraint(item: self.datePicker,
                                       attribute: .width,
                                       relatedBy: .equal,
                                       toItem: self.view,
                                       attribute: .width,
                                       multiplier: 1,
                                       constant: 0)
        
        let bottom = NSLayoutConstraint(item: self.datePicker,
                                        attribute: .bottom,
                                        relatedBy: .equal,
                                        toItem: self.cancelButton,
                                        attribute: .top,
                                        multiplier: 1,
                                        constant: 0)
        
        return [height, leading, width, bottom]
        
    }

    @IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func touchUpCancelButton(_ sender: UIButton) {
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func touchUpOkButton(_ sender: UIButton) {
        
        guard let year = self.selectedDate?.year, let month = self.selectedDate?.month else {
            return
        }
        
        let dreamListViewController = self.presentingViewController as? DreamListViewController
        
        let components : DateComponents = {
            var components = DateComponents()
            (components.year, components.month) = (year, month)
            return components
        }()
    
        if let selectedDate = Calendar(identifier: .gregorian).date(from: components) {
            dreamListViewController?.currentViewedDate = selectedDate
        }
        
        self.presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
}

extension DatePickerViewController : UIPickerViewDelegate, UIPickerViewDataSource {
    
    func numberOfComponents(in pickerView: UIPickerView) -> Int {
        return 2
    }
    
    func pickerView(_ pickerView : UIPickerView, numberOfRowsInComponent component: Int) -> Int {
        guard let dateType = DateType(rawValue: component) else {
            return 0
        }
        
        switch dateType {
            
        case .year :
            return years.count
            
        case .month :
            return DateParser.dateFormatter.monthSymbols.count
        
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, titleForRow row: Int, forComponent component: Int) -> String? {
        
        guard let dateType = DateType(rawValue: component) else {
            return nil
        }
        
        switch dateType {
            
        case .year:
            return "\(years[row])"
        case .month:
            return DateParser.dateFormatter.monthSymbols[row]
            
        }
    }
    
    func pickerView(_ pickerView: UIPickerView, didSelectRow row: Int, inComponent component: Int) {
        
        self.selectedDate?.year = years[self.datePicker.selectedRow(inComponent: DateType.year.rawValue)]
        self.selectedDate?.month = self.datePicker.selectedRow(inComponent: DateType.month.rawValue) + 1

    }
}

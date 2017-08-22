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
    
    var selectedDate : (year: Int?, month: Int?)?
    
    var years: [Int] = {
        
        var years : [Int] = []
        
        if var currentYear = DateParser().year(from: Date()) {
            for _ in 1 ... 30 {
                years.append(currentYear)
                currentYear -= 1
            }
        }
        
        return years
        
    }()
    
    override func viewDidLoad() {
        
        self.datePicker.backgroundColor = UIColor.dreamDarkPink
        self.datePicker.delegate = self
        self.datePicker.dataSource = self
        
        if let year = self.selectedDate?.year, let month = self.selectedDate?.month {
            
            self.datePicker.selectRow(year, inComponent: DateType.year.rawValue, animated: false)
            self.datePicker.selectRow(month - 1, inComponent: DateType.month.rawValue, animated: false)
            
        }
        
        view.backgroundColor = UIColor.clear.withAlphaComponent(0.5)
        view.isOpaque = false
        
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

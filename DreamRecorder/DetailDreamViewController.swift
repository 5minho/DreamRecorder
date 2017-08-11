//
//  DetailDreamViewController.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 10..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class DetailDreamViewController : UIViewController {
    
    static func storyboardInstance() -> DetailDreamViewController? {
        let storyboard = UIStoryboard(name: String(describing: self), bundle: nil)
        return storyboard.instantiateInitialViewController() as? DetailDreamViewController
    }
    
    enum Mode {
        case read
        case edit
    }
    
    var mode : Mode = .read {
        didSet {
            self.adjustViewMode()
        }
    }
    
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var createdDateLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var deleteButton: UIButton!
    
    private var isFirstShown: Bool = true
    
    weak var dreamDataStore : DreamDataStore?
    weak var dream : Dream?
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if let selectedDream = dream {
            
            titleField.text = selectedDream.title
            contentTextView.text = selectedDream.content
            createdDateLabel.text = SQLDateFormatter.string(from: selectedDream.createdDate)
            
        }
        
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if self.isFirstShown {
            
            self.adjustViewMode()
            
            self.isFirstShown = false
        }
        
    }
    
    @IBAction func backgroundTapped(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @objc private func touchUpEditBarButtonItem(_ sender : UIBarButtonItem) {
        self.mode = .edit
    }
    
    @objc private func touchUpDoneBarButtonItem(_ sender : UIBarButtonItem) {
        view.endEditing(true)
        self.dream?.title = titleField.text ?? ""
        self.dream?.content = contentTextView.text ?? ""
        self.dream?.modifiedDate = Date()
        guard let dream = self.dream else {
            return
        }
        dreamDataStore?.updateAlarm(dream: dream)
        self.mode = .read
        navigationController?.popViewController(animated: true)
    }
    
    private func adjustViewMode(){
        
        switch self.mode {
            
        case .read:
            
            self.deleteButton.isHidden = true
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit,
                                                                     target: self,
                                                                     action: #selector(touchUpEditBarButtonItem(_:)))
            self.titleField.isUserInteractionEnabled = false
            self.contentTextView.isUserInteractionEnabled = false
            
        case .edit:
            
            self.deleteButton.isHidden = false
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                                     target: self,
                                                                     action: #selector(touchUpDoneBarButtonItem(_:)))
            self.titleField.borderStyle = .roundedRect
            self.titleField.isUserInteractionEnabled = true
            self.contentTextView.isUserInteractionEnabled = true
            
        }
    }
}

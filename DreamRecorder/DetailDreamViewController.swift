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
    
    @IBOutlet weak var titleLabel: UILabel!
    @IBOutlet weak var titleField: UITextField!
    @IBOutlet weak var contentLabel: UILabel!
    @IBOutlet weak var createdDateLabel: UILabel!
    @IBOutlet weak var contentTextView: UITextView!
    @IBOutlet weak var deleteButton: UIButton!
    
    private var isFirstShown: Bool = true
    
    var dream : Dream?
    
    lazy var editButton : UIBarButtonItem  = {
        return UIBarButtonItem(barButtonSystemItem: .edit,
                               target: self,
                               action: #selector(touchUpEditBarButtonItem(_:)))
    }()
    
    lazy var doneButton : UIBarButtonItem = {
        return UIBarButtonItem(barButtonSystemItem: .done,
                               target: self,
                               action: #selector(touchUpDoneBarButtonItem(_:)))
    }()
    
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if let selectedDream = dream {
            
            titleField.text = selectedDream.title
            contentTextView.text = selectedDream.content
            
            if let createdDate = self.dream?.createdDate {
                createdDateLabel.text = DateParser().detail(from: createdDate)
            }
            
        }
        
        self.applyThemeIfViewDidLoad()
        self.setSubViewsColor()
        self.setBorderLayerColor()
    }
    
    override func viewWillAppear(_ animated: Bool) {
        
        super.viewWillAppear(animated)
        
        if self.isFirstShown {
            
            self.adjustViewMode()
            self.isFirstShown = false
            
        }
        
    }
    
    private func setBorderLayerColor() {
        
        self.titleField.layer.borderColor = UIColor.dreamTextColor1.cgColor
        self.contentTextView.layer.borderColor = UIColor.dreamTextColor1.cgColor
        
    }
    
    private func setSubViewsColor() {
        
        self.titleField.textColor = UIColor.dreamTextColor1
        self.contentTextView.textColor = UIColor.dreamTextColor1
        self.createdDateLabel.textColor = UIColor.dreamTextColor1
        self.titleLabel.textColor = UIColor.dreamTextColor1
        self.contentLabel.textColor = UIColor.dreamTextColor1
        self.deleteButton.setTitleColor(UIColor.dreamTextColor1, for: .normal)
        
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
        
        if let dream = self.dream {
            DreamDataStore.shared.update(dream: dream)
        }
        
        self.mode = .read
        
    }
    
    private func adjustViewMode() {
        
        switch self.mode {
            
        case .read:
            
            self.deleteButton?.isHidden = true
            self.navigationItem.rightBarButtonItem = editButton
            self.titleField?.layer.borderWidth = 0
            self.titleField?.isUserInteractionEnabled = false
            self.contentTextView?.isUserInteractionEnabled = false
            self.contentTextView?.layer.borderWidth = 0
            
        case .edit:
            
            self.deleteButton?.isHidden = false
            self.navigationItem.rightBarButtonItem = doneButton
            self.titleField?.layer.borderWidth = 1
            self.titleField?.isUserInteractionEnabled = true
            self.contentTextView?.isUserInteractionEnabled = true
            self.contentTextView?.layer.borderWidth = 1
            
        }
        
    }
    
}

extension DetailDreamViewController : DreamDeletable {
    
    @IBAction func touchupDeleteButton() {
        
        guard let dream = self.dream else {
            return
        }
        
        let alert = self.deleteAlert(dream: dream) {
            self.navigationController?.popViewController(animated: true)
        }
        
        self.present(alert, animated: true, completion: nil)
        
    }
    
}

extension DetailDreamViewController : ThemeAppliable {
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


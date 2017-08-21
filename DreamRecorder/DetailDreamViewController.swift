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
            
        }
        
        self.applyTheme()
        
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
        DreamDataStore.shared.update(dream: dream)
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


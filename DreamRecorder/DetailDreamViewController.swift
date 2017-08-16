//
//  DetailDreamViewController.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 10..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class DetailDreamViewController : UIViewController, DreamDeletable {
    
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
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        if let selectedDream = dream {
            
            let dateParser = DateParser()
            titleField.text = selectedDream.title
            contentTextView.text = selectedDream.content
            createdDateLabel.text = dateParser.detail(from: selectedDream.createdDate)
            
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
        
        DreamDataStore.shared.update(dream: dream)
        self.mode = .read
        
    }
    
    private func adjustViewMode(){
        
        switch self.mode {
            
        case .read:
            
            self.deleteButton.isHidden = true
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .edit,
                                                                     target: self,
                                                                     action: #selector(touchUpEditBarButtonItem(_:)))
            self.titleField.borderStyle = .none
            self.titleField.isUserInteractionEnabled = false
            self.contentTextView.isUserInteractionEnabled = false
            self.contentTextView.layer.borderWidth = 0
            
        case .edit:
            
            self.deleteButton.isHidden = false
            self.navigationItem.rightBarButtonItem = UIBarButtonItem(barButtonSystemItem: .done,
                                                                     target: self,
                                                                     action: #selector(touchUpDoneBarButtonItem(_:)))
            self.titleField.borderStyle = .roundedRect
            self.titleField.isUserInteractionEnabled = true
            self.contentTextView.isUserInteractionEnabled = true
            self.contentTextView.layer.borderWidth = 1
            
        }
    }
    
    @IBAction func touchUpdeleteButton(_ sender: UIButton) {
        
        if let dream = self.dream {
            
            let alert = deleteAlert(dream: dream, completion: {
                self.navigationController?.popViewController(animated: true)
            })
            
            self.present(alert, animated: true, completion: nil)
        }
        
    }
    
}

//
//  DreamDeletable.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 16..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

protocol DreamDeletable {
    
    func deleteAlert(dream: Dream, completion : (() -> Void)?) -> UIAlertController
    
}

extension DreamDeletable {
    
    func deleteAlert(dream: Dream, completion : (() -> Void)?) -> UIAlertController {
        
        let title = "Delete \(dream.title!)?"
        let message = "Are you sure you want to delete this dream?"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let cencelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cencelAction)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action) -> Void in
            DreamDataStore.shared.delete(dream: dream)
            
            if let handler = completion {
                handler()
            }
        })
        
        alert.addAction(deleteAction)
        return alert
    }
    
}


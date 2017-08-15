//
//  DreamDeletable.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 16..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

protocol DreamDeletable {
    
    var dreamDataStore : DreamDataStore {get}
    func deleteAlert(dream: Dream, complement : (() -> Void)?) -> UIAlertController
    
}

extension DreamDeletable {
    
    var dreamDataStore : DreamDataStore {
        return DreamDataStore.shared
    }
    
    func deleteAlert(dream: Dream, complement : (() -> Void)?) -> UIAlertController {
        
        let title = "Delete \(dream.title!)?"
        let message = "Are you sure you want to delete this dream?"
        
        let alert = UIAlertController(title: title, message: message, preferredStyle: .actionSheet)
        let cencelAction = UIAlertAction(title: "Cancel", style: .cancel, handler: nil)
        alert.addAction(cencelAction)
        
        let deleteAction = UIAlertAction(title: "Delete", style: .destructive, handler: { (action) -> Void in
            self.dreamDataStore.delete(dream: dream)
            if let handler = complement {
                handler()
            }
        })
        
        alert.addAction(deleteAction)
        return alert
    }
    
}

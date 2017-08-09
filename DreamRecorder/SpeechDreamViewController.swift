//
//  SpeechDreamViewController.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 8..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit
import AVFoundation
import NaverSpeech

class SpeechDreamViewController : UIViewController {
    
    @IBOutlet weak var contentField: UITextView!
    @IBOutlet weak var recongnitionStateLabel: UILabel!
    fileprivate let speechRecognizer : NSKRecognizer
    fileprivate var previousText : String = ""
    
    required init?(coder aDecoder: NSCoder) {
        let configuration = NSKRecognizerConfiguration(clientID: Config.clientID)
        configuration?.canQuestionDetected = true
        configuration?.epdType = .manual
        self.speechRecognizer = NSKRecognizer(configuration: configuration)
        super.init(coder: aDecoder)
        self.speechRecognizer.delegate = self
    }

    @IBAction func recognitionButtonPressed(_ sender: UILongPressGestureRecognizer) {
        if sender.state == .began {
            if !speechRecognizer.isRunning {
                try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategoryRecord)
                self.speechRecognizer.start(with: .korean)
            }
        }
    }
    
    @IBAction func doneRecordDream(_ sender: UIBarButtonItem) {
        speechRecognizer.stop()
        
        let alert = UIAlertController(title: "title", message: "please enter a title", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Enter a title"
            textField.clearButtonMode = .whileEditing
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { [unowned self] action in
            var title = ""
            if let inputTitle = alert.textFields?.first?.text {
                title = inputTitle
            }
            
            if title.isEmpty {
                title = "No title"
            }
            
            let newDream = Dream(id: UUID().uuidString, title: title, content: self.contentField.text, createdDate: Date(), modifiedDate: nil)
            let navigationController = self.navigationController as? AddDreamNavigationController
            navigationController?.dreamDataStore?.insert(dream: newDream)
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { [unowned self] action in
            self.presentingViewController?.dismiss(animated: true, completion: nil)
        }
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true, completion: nil)
    }
    
    @IBAction func cancelRecord(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func recognitionViewTapped(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
   
}


extension SpeechDreamViewController : NSKRecognizerDelegate {
    public func recognizerDidEnterReady(_ aRecognizer: NSKRecognizer!) {
        print("Event occurred: Ready")
        recongnitionStateLabel.text = "Recognizing......"
    }
    
    public func recognizerDidDetectEndPoint(_ aRecognizer: NSKRecognizer!) {
        print("Event occurred: End point detected")
    }
    
    public func recognizerDidEnterInactive(_ aRecognizer: NSKRecognizer!) {
        print("Event occurred: Inactive")
        try? AVAudioSession.sharedInstance().setCategory(AVAudioSessionCategorySoloAmbient)
    }
    
    public func recognizer(_ aRecognizer: NSKRecognizer!, didRecordSpeechData aSpeechData: Data!) {
        print(aSpeechData.description)
        print("Record speech data, data size: \(aSpeechData.count)")
    }
    
    public func recognizer(_ aRecognizer: NSKRecognizer!, didReceivePartialResult aResult: String!) {
        print("Partial result: \(aResult)")
        if aResult.isEmpty {
            previousText = contentField.text
            contentField.text = previousText
        }
        contentField.text = aResult
    }
    
    public func recognizer(_ aRecognizer: NSKRecognizer!, didReceiveError aError: Error!) {
        print("Error: \(aError)")
        
    }
    
    public func recognizer(_ aRecognizer: NSKRecognizer!, didReceive aResult: NSKRecognizedResult!) {
        print("Final result: \(aResult)")
        recongnitionStateLabel.text = "end recognize"
    }
}

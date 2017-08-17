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
    fileprivate var defaultText : String = ""
    @IBOutlet weak var recordButton: RecordButton!
    
    override func viewDidLoad() {
        
        super.viewDidLoad()
        
        let contentFieldLayer = self.contentField.layer
        contentFieldLayer.borderWidth = 1
        contentFieldLayer.borderColor = UIColor.black.cgColor
        self.applyTheme()
    }
    
    let audioDispatch = DispatchQueue(label: "audioSerialQueue")
    
    required init?(coder aDecoder: NSCoder) {
        let configuration = NSKRecognizerConfiguration(clientID: Config.clientId)
        configuration?.canQuestionDetected = true
        configuration?.epdType = .manual
        
        self.speechRecognizer = NSKRecognizer(configuration: configuration)
        super.init(coder: aDecoder)
        self.speechRecognizer.delegate = self
    }
    
    override func viewWillDisappear(_ animated: Bool) {
        
        super.viewWillDisappear(animated)
        self.view.endEditing(true)
        self.inActivateRecognizer()
        
    }

    
    @IBAction func doneRecordDream(_ sender: UIBarButtonItem) {
        
        speechRecognizer.stop()
        
        let alert = UIAlertController(title: "title", message: "please enter a title", preferredStyle: .alert)
        alert.addTextField { textField in
            textField.placeholder = "Enter a title"
            textField.clearButtonMode = .whileEditing
        }
        
        let saveAction = UIAlertAction(title: "Save", style: .default) { action in
            
            var title = ""
            if let inputTitle = alert.textFields?.first?.text {
                title = inputTitle
            }
            
            if title.isEmpty {
                title = "No title"
            }
            
            let newDream = Dream(id: UUID().uuidString,
                                 title: title, content: self.contentField.text,
                                 createdDate: Date(),
                                 modifiedDate: nil)
            
            DreamDataStore.shared.insert(dream: newDream)
            self.presentingViewController?.dismiss(animated: true, completion: nil)
            
        }
        
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel)
        
        alert.addAction(saveAction)
        alert.addAction(cancelAction)
        present(alert, animated: true)
        
    }
    
    @IBAction func cancelRecord(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true, completion: nil)
    }
    
    @IBAction func recognitionViewTapped(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @IBAction func touchUpRecordButton(_ sender: UIButton) {
        
        speechRecognizer.isRunning ? inActivateRecognizer() : activateRecognizer()
        
    }
    
    private func activateRecognizer() {
        
        if speechRecognizer.isRunning == false {
            
            self.recordButton.recordState = .recording
            speechRecognizer.start(with: .korean)
            asyncSetAudioCategory(AVAudioSessionCategoryRecord) {
                DispatchQueue.main.async {
                    self.recongnitionStateLabel.text = "Recognize..."
                }
            }
            
        }
        
    }
    
    private func inActivateRecognizer() {
        
        if speechRecognizer.isRunning {
            
            self.recordButton.recordState = .idle
            speechRecognizer.stop()

        }
        
    }
    
    fileprivate func asyncSetAudioCategory(_ category: String, completion: (() -> Void)?) {
        audioDispatch.async {
            try? AVAudioSession.sharedInstance().setCategory(category)
        }
        if let completeHandler = completion {
            completeHandler()
        }
    }

}

extension SpeechDreamViewController : NSKRecognizerDelegate {
    
    public func recognizerDidEnterReady(_ aRecognizer: NSKRecognizer!) {
        print("Event occurred: Ready")
    }
    
    public func recognizerDidDetectEndPoint(_ aRecognizer: NSKRecognizer!) {
        print("Event occurred: End point detected")
    }
    
    func recognizer(_ aRecognizer: NSKRecognizer!, didSelectEndPointDetectType aEPDType: NSNumber!) {
        print("didSelectEndPointDetectType")
    }
    
    public func recognizerDidEnterInactive(_ aRecognizer: NSKRecognizer!) {
        print("Event occurred: Inactive")
        
        if recordButton.recordState == .recording {
            self.speechRecognizer.start(with: .korean)
            return
        }
        
        asyncSetAudioCategory(AVAudioSessionCategorySoloAmbient) {
            DispatchQueue.main.async {
                self.recongnitionStateLabel.text = "end recognize"
            }
        }

    }
    
    public func recognizer(_ aRecognizer: NSKRecognizer!, didRecordSpeechData aSpeechData: Data!) {
        print(aSpeechData.description)
        print("Record speech data, data size: \(aSpeechData.count)")
    }
    
    public func recognizer(_ aRecognizer: NSKRecognizer!, didReceivePartialResult aResult: String!) {
        print("Partial result: \(aResult)")

        if aResult.isEmpty {
            contentField.text = defaultText + " " + previousText
            return
        }
        
        previousText = aResult
        contentField.text = defaultText + " " + previousText
    }
    
    public func recognizer(_ aRecognizer: NSKRecognizer!, didReceiveError aError: Error!) {
        print("Error: \(aError)")
    }
    
    public func recognizer(_ aRecognizer: NSKRecognizer!, didReceive aResult: NSKRecognizedResult!) {
        
        print("Final result: \(aResult)")
        let lastResult = aResult.results.first as? String
        
        previousText = ""
        if let result = lastResult {
            contentField.text = defaultText + " " + result
            defaultText = contentField.text
        }
        
    }
}

extension SpeechDreamViewController : ThemeAppliable {
    
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

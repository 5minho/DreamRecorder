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
    
    override func viewDidLoad() {
        super.viewDidLoad()
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
        print("제목입력")
        speechRecognizer.stop()
    }
    
    @IBAction func cancelRecord(_ sender: UIBarButtonItem) {
        presentingViewController?.dismiss(animated: true, completion: nil)
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
        
        if let result = aResult.results.first as? String {
            recongnitionStateLabel.text = "end recognize"
        }
    }
}

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
import Speech


@available(iOS 10.0, *)
class SpeechDreamViewController : UIViewController {
    
    @IBOutlet weak var contentField: UITextView!
    @IBOutlet weak var recongnitionStateLabel: UILabel!
    fileprivate var previousText : String = ""
    fileprivate var defaultText : String = ""
    
    fileprivate let speechRecognizer : NSKRecognizer
    
    ////////////
    fileprivate let appleRecognizer = SFSpeechRecognizer(locale : Locale(identifier: "ko_KR"))
    fileprivate var recognitionRequest: SFSpeechAudioBufferRecognitionRequest?
    fileprivate var recognitionTask: SFSpeechRecognitionTask?
    fileprivate let audioEngine = AVAudioEngine()
    ////////////
    
    
    @IBOutlet weak var recordButton: RecordButton!
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        ///////////////
        SFSpeechRecognizer.requestAuthorization { (authStatus) in
            
            var isButtonEnabled = false
            
            switch authStatus {  //5
            case .authorized:
                isButtonEnabled = true
                
                OperationQueue.main.addOperation() {
                    self.recordButton.isEnabled = isButtonEnabled
                }
                
            case .denied:
                isButtonEnabled = false
                print("User denied access to speech recognition")
                
            case .restricted:
                isButtonEnabled = false
                print("Speech recognition restricted on this device")
                
            case .notDetermined:
                isButtonEnabled = false
                print("Speech recognition not yet authorized")
            }

        }
        ///////////////
        
        let contentFieldLayer = self.contentField.layer
        contentFieldLayer.borderWidth = 1
        contentFieldLayer.borderColor = UIColor.black.cgColor
//        self.applyTheme()
        
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
        
//        speechRecognizer.isRunning ? inActivateRecognizer() : activateRecognizer()
        
        if audioEngine.isRunning {
            audioEngine.stop()
            recognitionRequest?.endAudio()
            recordButton.isEnabled = false
            recordButton.setTitle("Start Recording", for: .normal)
        } else {
            startRecording()
            recordButton.setTitle("Stop Recording", for: .normal)
        }
        
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

@available(iOS 10.0, *)
extension SpeechDreamViewController : SFSpeechRecognizerDelegate {
    
    func speechRecognizer(_ speechRecognizer: SFSpeechRecognizer, availabilityDidChange available: Bool) {
        if available {
            recordButton.isEnabled = true
        } else {
            recordButton.isEnabled = false
        }
    }
    
    func startRecording() {
        
        if recognitionTask != nil {
            recognitionTask?.cancel()
            recognitionTask = nil
        }
        
        let audioSession = AVAudioSession.sharedInstance()
        do {
            try audioSession.setCategory(AVAudioSessionCategoryRecord)
            try audioSession.setMode(AVAudioSessionModeMeasurement)
            try audioSession.setActive(true, with: .notifyOthersOnDeactivation)
        } catch {
            print("audioSession properties weren't set because of an error.")
        }
        
        recognitionRequest = SFSpeechAudioBufferRecognitionRequest()
        
        guard let inputNode = audioEngine.inputNode else {
            fatalError("Audio engine has no input node")
        }
        
        guard let recognitionRequest = recognitionRequest else {
            fatalError("Unable to create an SFSpeechAudioBufferRecognitionRequest object")
        }
        
        recognitionRequest.shouldReportPartialResults = true
        
        recognitionTask = appleRecognizer?.recognitionTask(with: recognitionRequest, resultHandler: { (result, error) in
            
            var isFinal = false
            
            if result != nil {
                
                self.contentField.text = result?.bestTranscription.formattedString
                isFinal = (result?.isFinal)!
            }
            
            if error != nil || isFinal {
                self.audioEngine.stop()
                inputNode.removeTap(onBus: 0)
                
                self.recognitionRequest = nil
                self.recognitionTask = nil
                
                self.recordButton.isEnabled = true
            }
        })
        
        let recordingFormat = inputNode.outputFormat(forBus: 0)
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: recordingFormat) { (buffer, when) in
            self.recognitionRequest?.append(buffer)
        }
        
        audioEngine.prepare()
        
        do {
            try audioEngine.start()
        } catch {
            print("audioEngine couldn't start because of an error.")
        }
        
        contentField.text = "Say something, I'm listening!"
        
    }
    
}

@available(iOS 10.0, *)
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

@available(iOS 10.0, *)
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

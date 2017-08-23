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
    @IBOutlet weak var todayLabel: UILabel!
    @IBOutlet weak var recordButton: RecordButton!
    @IBOutlet weak var leftTimeLabel: UILabel!
    
    fileprivate var previousText : String = ""
    fileprivate var defaultText : String = ""
    fileprivate var equalCount = 0
    
    fileprivate let speechRecognizer : NSKRecognizer
    
    fileprivate var isTimerRunning = false
    fileprivate var leftTime = 10
    fileprivate var timer  = Timer()
    
    override func viewDidLoad() {
        super.viewDidLoad()
        
        todayLabel.text = DateParser().detail(from: Date())
        setContentFieldLayer()
        self.applyThemeIfViewDidLoad()
        
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
        self.applyThemeIfViewWillAppear()
        
    }

    
    @IBAction func doneRecordDream(_ sender: UIBarButtonItem) {
        
        finishTimer()
        inActivateRecognizer()
        
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
        
        finishTimer()
        inActivateRecognizer()
        presentingViewController?.dismiss(animated: true, completion: nil)
        
    }
    
    @IBAction func recognitionViewTapped(_ sender: UITapGestureRecognizer) {
        view.endEditing(true)
    }
    
    @IBAction func touchUpRecordButton(_ sender: UIButton) {
        
        finishTimer()
        speechRecognizer.isRunning ? inActivateRecognizer() : activateRecognizer()
        
    }
    
    fileprivate func startTimer() {
        
        isTimerRunning = true
        self.leftTime = 10
        self.timer = Timer.scheduledTimer(timeInterval: 1,
                                          target: self,
                                          selector: #selector(updateLeftTime),
                                          userInfo: nil,
                                          repeats: true)
        
    }
    
    func setContentFieldLayer() {
        
        let contentFieldLayer = self.contentField.layer
        contentFieldLayer.borderWidth = 1
        contentFieldLayer.borderColor = UIColor.black.cgColor
        
    }
    
    fileprivate func finishTimer() {
        
        isTimerRunning = false
        self.timer.invalidate()
        self.leftTimeLabel.text = ""
        
    }
    
    @objc private func updateLeftTime() {
        
        if self.leftTime == 1 {
            
            self.inActivateRecognizer()
            self.finishTimer()
            return
            
        }
        
        self.leftTime -= 1
        
        self.leftTimeLabel.text = "\(self.leftTime)초 후에 마이크가 꺼집니다."
    
    }
    
    private func activateRecognizer() {
        
        if speechRecognizer.isRunning == false {
            
            speechRecognizer.start(with: .korean)
            self.recordButton.recordState = .recording
            asyncSetAudioCategory(AVAudioSessionCategoryRecord)
            
        }
        
    }
    
    private func inActivateRecognizer() {
        
        if speechRecognizer.isRunning {
            
            self.recordButton.recordState = .idle
            speechRecognizer.stop()

        }
        
    }
    
    fileprivate func asyncSetAudioCategory(_ category: String, _ completion: (() -> Void)? = nil) {
        
        audioDispatch.async {
            
            try? AVAudioSession.sharedInstance().setCategory(category)
            if let completeHandler = completion {
                completeHandler()
            }
            
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
        
        asyncSetAudioCategory(AVAudioSessionCategorySoloAmbient)
        
    }
    
    public func recognizer(_ aRecognizer: NSKRecognizer!, didRecordSpeechData aSpeechData: Data!) {
        
        print(aSpeechData.description)
        print("Record speech data, data size: \(aSpeechData.count)")
        
    }
    
    public func recognizer(_ aRecognizer: NSKRecognizer!, didReceivePartialResult aResult: String!) {
        print("Partial result: \(aResult)")
        
        if !isTimerRunning {
            equalCount = (previousText == aResult) ? equalCount + 1 : equalCount
            
            if equalCount == 15 {
                
                equalCount = 0
                self.startTimer()
                
            }
        }
        
        if previousText != aResult {
            self.finishTimer()
        }
        
        if aResult.isEmpty {
            contentField.text = defaultText + " " + previousText
            return
        }
        
        previousText = aResult
        contentField.text = defaultText + " " + previousText
    }
    
    public func recognizer(_ aRecognizer: NSKRecognizer!, didReceiveError aError: Error!) {
        print("Error: \(aError)")
        
        guard let error = aError as? NMSpeechRecognizerError else {
            
            present(UIAlertController.simpleAlert(title: "오류 발생".localized), animated: false, completion: nil)
            return
            
        }
        
        switch error {
            
        case .errorNetworkNACK, .errorNetworkRead, .errorNetworkWrite, .errorNetworkInitialize, .errorNetworkFinalize:
            present(UIAlertController.simpleAlert(title: "네트워크 오류 [\(error.rawValue)]".localized, message: "네트워크연결을 확인해 주세요".localized), animated: false, completion: nil)
        case .errorAudioFinalize, .errorAudioInitialize, .errorAudioRecord :
            present(UIAlertController.simpleAlert(title: "오디오 오류 [\(error.rawValue)]".localized), animated: false, completion: nil)
            
        default:
            present(UIAlertController.simpleAlert(title: "오류 [\(error.rawValue)]".localized), animated: false, completion: nil)
            
        }
        
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
    
}

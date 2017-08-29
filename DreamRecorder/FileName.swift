//
//  FileName.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 29..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import Foundation

struct DispatchQueueLabel{
    
    static let audioSerialQueue = "audioSerialQueue"
    
}

struct SoundFileName {
    static let defaultSound = "Default.wav"
}

struct DefaultLableText {
    
    static let defaultAlarmName = "Alarm".localized
    
}

struct TabbarTitle {
    
    static let dreamTab = "Dream".localized
    static let alarmTab = "Alarm".localized
    static let settingTab = "Setting".localized
    
}

struct BarButtonText {
    
    static let cancel = "Cancel".localized
    static let save = "Save".localized
    
}

struct AlartText {
    
    static let cancel = "Cancel".localized
    static let done = "Done".localized
    static let alarmName = "Label".localized
    static let dreamTitle = "Dream Title".localized
    
}

struct NavigationTitle {
    
    static let addAlarm = "Add Alarm".localized
    static let editAlarm = "Edit Alarm".localized
}


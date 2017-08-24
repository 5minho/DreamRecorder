//
//  CocoaTouchExtension.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 9..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//
import Foundation
import SQLite

// MARK: Foundation
// Foundation DataType을 sqlite database가 지원하는 포맷으로 Extension함.
extension WeekdayOptions: Value {
    // WeekdayOptions을 Int로 읽어드리면 에러가 발생, Int64로 감싸서 읽고/쓰기 실행.
    static var declaredDatatype: String {
        return Int64.declaredDatatype
    }
    static func fromDatatypeValue(_ datatypeValue: Int64) -> WeekdayOptions {
        return WeekdayOptions(rawValue: Int(datatypeValue))
    }
    var datatypeValue: Int64 {
        return Int64(rawValue)
    }
}

extension Bool {
    static var declaredDatatype: String {
        return Int.declaredDatatype
    }
    static func fromDatatypeValue(intValue: Int) -> Bool {
        return intValue == 1 ? true : false
    }
    var datatypeValue: Int {
        return self ? 1 : 0
    }
}

extension String {
    
    var localized: String {
        return NSLocalizedString(self, comment: "")
    }
    
    func localized(comment: String) -> String {
        return NSLocalizedString(self, comment: comment)
    }
    
}

extension Date {
    static var declaredDatatype: String {
        return Int.declaredDatatype
    }
    static func fromDatatypeValue(intValue: Int) -> Date {
        return self.init(timeIntervalSince1970: TimeInterval(intValue))
    }
    var datatypeValue: Int {
        return Int(timeIntervalSince1970)
    }
}

extension Date {
    func removingSeconds() -> Date {
        let dateComponents = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute, .minute], from:
            self)
        let secondRemovedDate = Calendar.current.date(from: dateComponents)
        return secondRemovedDate ?? self
    }
}

extension Date {
    
    var addingSnoozeTimeInterval: Date {
        return self.addingTimeInterval(60*9)
    }
    
}

extension Array {
    
    subscript (safe index: Int) -> Element? {
        return indices ~= index ? self[index] : nil
    }
    
}

extension UIAlertController {
    
    static func simpleAlert(title: String, message : String? = nil) -> UIAlertController {
        
        let alertController = UIAlertController(title: title, message: message, preferredStyle: .alert)
        let action = UIAlertAction(title: "확인".localized, style: .default, handler: nil)
        alertController.addAction(action)
        
        return alertController
    }
    
}

import AVFoundation

extension String {
    // MARK: - Sound Path.
    /// 알람 클래스의 sound프로퍼티는 sound path값을 지닌다.
    /// 번들에 포함된 알람음과 사용자 Media에 있는 음악 파일Path 중 하나를 가질 수 있다.
    var soundTitle: String? {
        
        if self.hasPrefix("ipod-library:") {
            guard let url = URL(string: self) else { return "Unknown title".localized }
            
            let asset = AVAsset(url: url)
            
            for metaItem in asset.commonMetadata {
                guard metaItem.commonKey == AVMetadataCommonKeyTitle else { continue }
                return metaItem.stringValue
            }
            return "Unknown title".localized
            
        } else {
            return self.components(separatedBy: ".").first
        }
    }
    
    /// 알람 클래스의 sound path값이 번들 파일의 path값일 경우 soundFormat을 .을 구분자로 하여 확장자를 가져올 수 있다.
    var soundFormat: String? {
        return self.components(separatedBy: ".").last
    }
    
    /// 알람 클래스의 sound path값을 번들파일과 미디어파일 각각의 Asset URL를 얻을 수 있다.
    var soundURL: URL? {
        if self.hasPrefix("ipod-library:") {
            return URL(string: self)
        } else {
            guard let fileFormat = self.components(separatedBy: ".").last else { return nil }
            guard let path = Bundle.main.path(forResource: self.soundTitle, ofType: fileFormat) else { return nil }
            return URL(fileURLWithPath: path)
        }
    }
}

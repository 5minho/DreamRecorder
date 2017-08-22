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
// extension dataType to read and write at sqlite database for type suppport
// TRICK: reading WeekdayOptions as Int invoke error, so use Int64 as Int Wrapper.

extension WeekdayOptions: Value {
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


import AVFoundation

//extension AVAsset: NSCoding {
//    
//    
//    
//}

extension String {
    // @discussion      Note that alarm class can have two type of sound path.
    //                  One is ipod-library for media item user have.
    //                  Another is main bundle sound files.
    var soundTitle: String? {
        if self.hasPrefix("ipod-library:") {
            guard let url = URL(string: self) else { return self }
            let asset = AVAsset(url: url)
            for metaItem in asset.commonMetadata {
                if metaItem.commonKey == AVMetadataCommonKeyTitle {
                    return metaItem.stringValue
                }
            }
            return nil
        } else {
            return self.components(separatedBy: ".").first
        }
    }
    
    var soundFormat: String? {
        return self.components(separatedBy: ".").last
    }
    
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

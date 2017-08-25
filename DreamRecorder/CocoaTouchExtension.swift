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

extension UIColor {
    /// 한가지 색상을 이용하여 1x1의 이미지를 생성한다.
    ///
    /// UIGraphicsGetImageFromCurrentImageContext()를 통해 이미지를 얻지 못할 경우에는 UIImage()를 반환한다.
    ///
    /// - Parameter color: UIImage의 배경색상에 활용 될 UIColor.
    /// - Returns: 파라미터로 전달된 UIColor를 통해 1x1의 이미지를 반환한다.
    func shadowImage() -> UIImage {
        defer {
            UIGraphicsEndImageContext()
        }
        
        let imageContextSize = CGSize(width: 1, height: 1)
        UIGraphicsBeginImageContextWithOptions(imageContextSize, false, 0)
        
        self.setFill()
        UIRectFill(CGRect(origin: .zero, size: CGSize(width: 1, height: 1)))
        
        let filledImage = UIGraphicsGetImageFromCurrentImageContext()
        return filledImage ?? UIImage()
    }
}

extension UIImage {
    /// 이미지를 특정 사이즈의 이미지로 반환합니다.
    ///
    /// UIImageView의 같은 경우 ContentMode로 이미지의 표시여부를 조정할 수 있지만
    /// UITabbar의 이미지로 쓰의거나 UITableViewCell에서의 image로 활용될 경우 이미지크기그대로 보여진다.
    ///
    /// 물론 특정 공간(셀이나 텝바)에서만 사용될 경우 이미지의 사이즈를 최소화 하여 용량을 줄이는 것이 현명하지만
    /// Setting에 있는 UITableViewCell또한 Dynamic type을 지원하므로 Image가 같이가는 것이 보기 좋을 것이다.
    func image(with size: CGSize) -> UIImage? {
        defer {
            UIGraphicsEndImageContext()
        }
        UIGraphicsBeginImageContextWithOptions(size, false, 0)
        self.draw(in: CGRect(x: 0, y: 0, width: size.width, height: size.height))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        return resizedImage
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

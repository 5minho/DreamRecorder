//
//  DreamFont.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 16..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

class CustomFont {
    
    // MARK: - Properties.
    // - Singleton.
    static let current: CustomFont = CustomFont()
    
    // - Custom font name.
    static var customFontName: String = {
        return UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Bold" : "HelveticaNeue-Light"
    }()
    
    // - Whether system font or custom font.
    fileprivate var isSystemFont = UserDefaults.standard.bool(forKey: UserDefaults.UserKey.isSystemFont)
    
    init() {
        NotificationCenter.default.addObserver(forName: .UIAccessibilityBoldTextStatusDidChange,
                                               object: self,
                                               queue: OperationQueue.main)
        {
            (notification) in
            
            CustomFont.customFontName = UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Bold" : "HelveticaNeue-Light"
        }
    }
    
    /// 현재 설정된 값이 SystemFont인지 아닌지를 판단하여 폰트를 반환한다.
    /// 반환될 폰트의 사이즈는 시스템에 의해 설정된 크기(Larger Accessibility Sizes)를 가져와서 반영한다.
    ///
    /// - Parameter textStyle: text에 쓰임새에 따른 style.
    /// - Returns: textStyle에 해당하는 폰트를 반환한다.
    fileprivate func userPreferredFont(forTextStyle textStyle: UIFontTextStyle) -> UIFont {
        let systemFont = UIFont.preferredFont(forTextStyle: textStyle)
        if self.isSystemFont == true,
            let customFont = UIFont(name: CustomFont.customFontName, size: systemFont.pointSize) {
            return customFont
        } else {
            return systemFont
        }
    }
    
    /// 폰트 설정값을 UserDefaults에서 다시 불러온다.
    func reloadFont() {
        self.isSystemFont = UserDefaults.standard.bool(forKey: UserDefaults.UserKey.isSystemFont)
    }
}

extension UIFont {
    
    static var title1: UIFont {
        return CustomFont.current.userPreferredFont(forTextStyle: .title1)
    }
    
    static var title2: UIFont {
        return CustomFont.current.userPreferredFont(forTextStyle: .title2)
    }
    
    static var title3: UIFont {
        return CustomFont.current.userPreferredFont(forTextStyle: .title2)
    }
    
    static var body: UIFont {
        return CustomFont.current.userPreferredFont(forTextStyle: .body)
    }
    
    static var callout: UIFont {
        return CustomFont.current.userPreferredFont(forTextStyle: .callout)
    }
    
    static var caption1: UIFont {
        return CustomFont.current.userPreferredFont(forTextStyle: .caption1)
    }
    
    static var caption2: UIFont {
        return CustomFont.current.userPreferredFont(forTextStyle: .caption2)
    }
}

extension UserDefaults {
    struct UserKey {
        static let isSystemFont = "isSystemFont"
    }
}

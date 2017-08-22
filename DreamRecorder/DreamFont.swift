//
//  DreamFont.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 16..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

extension UserDefaults {
    struct UserKey {
        static let isSystemFont = "isSystemFont"
    }
}

class CustomFont {
    
    static let current: CustomFont = CustomFont()
    
    static var customFontName: String = {
        return UIAccessibilityIsBoldTextEnabled() ? "HelveticaNeue-Bold" : "HelveticaNeue-Light"
    }()
    
    var isSystemFont = UserDefaults.standard.bool(forKey: UserDefaults.UserKey.isSystemFont)
    
    func reloadFont() {
        self.isSystemFont = UserDefaults.standard.bool(forKey: UserDefaults.UserKey.isSystemFont)
    }
    
    fileprivate func userPreferredFont(forTextStyle textStyle: UIFontTextStyle) -> UIFont {
        let systemFont = UIFont.preferredFont(forTextStyle: textStyle)
        if self.isSystemFont == true,
            let customFont = UIFont(name: CustomFont.customFontName, size: systemFont.pointSize) {
            return customFont
        } else {
            return systemFont
        }
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

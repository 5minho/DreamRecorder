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
    
    // - Internal.
    /// 폰트 이름 배열.
    lazy var userFontNames: [String] = ["System",
                                        "AppleSDGothicNeo-Light",
                                        "HelveticaNeue-Light",
                                        "Verdana",
                                        "TimesNewRomanPSMT"]
    
    // - Private.
    /// 폰트 이름에 해당하는 각각의 Bold체.
    private lazy var userFontNamesBold: [String] = ["System",
                                                    "AppleSDGothicNeo-Bold",
                                                    "HelveticaNeue-Bold",
                                                    "Verdana-Bold",
                                                    "TimesNewRomanPS-BoldMT"]
    
    /// 사용자가 설정창에서 설정한 폰트 이름. (Bold 반영x)
    /// 만약 시스템폰트를 사용한다면 nil을 반환.
    lazy fileprivate var userFontName: String? = UserDefaults.standard.string(forKey: UserDefaults.UserKey.fontName)

    /// 사용자가 설정한 폰트명을 가지고 Accessibility Bold Text여부를 통해 기본 또는 Bold폰트를 반환. (사이즈 반영x)
    /// 만약 적절한 폰트명을 찾지 못하면 nil을 반환한다. 반환된 nil은 userPreferredFont에서 System폰트로 반환하게 된다.
    lazy var styledUserFontName: String? = {
        return self.loadStyledFontName()
    }()
    
    init() {
        
        NotificationCenter.default.addObserver(forName: .UIAccessibilityBoldTextStatusDidChange,
                                               object: self,
                                               queue: OperationQueue.main)
        {
            (notification) in
            
            self.reloadFont()
        }
    }
    
    /// 현재 설정된 값이 SystemFont인지 아닌지를 판단하여 폰트를 반환한다.
    /// 반환될 폰트의 사이즈는 시스템에 의해 설정된 크기(Larger Accessibility Sizes)를 가져와서 반영한다.
    ///
    /// - Parameter textStyle: text에 쓰임새에 따른 style.
    /// - Returns: textStyle에 해당하는 폰트를 반환한다.
    fileprivate func userPreferredFont(forTextStyle textStyle: UIFontTextStyle) -> UIFont {
        let systemFont = UIFont.preferredFont(forTextStyle: textStyle)
        if let styledUserFontName = self.styledUserFontName {
            let customFont = UIFont(name: styledUserFontName, size: systemFont.pointSize)
            return customFont ?? systemFont
        } else {
            return systemFont
        }
    }
    
    private func loadStyledFontName() -> String? {
        guard let userFontName = self.userFontName else { return nil }
        
        if UIAccessibilityIsBoldTextEnabled() {
            guard let index = self.userFontNames.index(of: userFontName) else { return nil }
            return self.userFontNamesBold[index]
        } else {
            return userFontName
        }
    }
    
    /// UserDefaults에 저장된 사용자가 선택한 폰트명을 업데이트한다.(폰트 업데이트)
    /// userPreferredFont가 참조하는 styledUserFontName의 값을 업데이트한다.(Bold업데이트)
    func reloadFont() {
        self.userFontName = UserDefaults.standard.string(forKey: UserDefaults.UserKey.fontName)
        self.styledUserFontName = self.loadStyledFontName()
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
        static let fontName = "DreamRecorder.fontName"
    }
}

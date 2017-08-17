//
//  DreamFont.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 16..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import UIKit

extension UIFont {
    static var title1: UIFont {
        return UIFont(name: "HelveticaNeue-Light", size: UIFont.preferredFont(forTextStyle: UIFontTextStyle.title1).pointSize) ?? UIFont.preferredFont(forTextStyle: UIFontTextStyle.title1)
    }
    static var title3: UIFont {
        return UIFont(name: "HelveticaNeue-Light", size: UIFont.preferredFont(forTextStyle: UIFontTextStyle.title3).pointSize) ?? UIFont.preferredFont(forTextStyle: UIFontTextStyle.title3)
    }
    static var caption: UIFont {
        return UIFont(name: "HelveticaNeue-Light", size: UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1).pointSize) ?? UIFont.preferredFont(forTextStyle: UIFontTextStyle.caption1)
    }
    static var body: UIFont {
        return UIFont(name: "HelveticaNeue-Light", size: UIFont.preferredFont(forTextStyle: UIFontTextStyle.body).pointSize) ?? UIFont.preferredFont(forTextStyle: UIFontTextStyle.body)
    }
}

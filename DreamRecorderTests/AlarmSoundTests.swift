//
//  AlarmSoundTests.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 25..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//


import XCTest
@testable import DreamRecorder

class AlarmSoundTests: XCTestCase {
    func testFontNames() {
        for familyName in UIFont.familyNames {
            print("===================\(familyName)======================")
            for fontName in UIFont.fontNames(forFamilyName: familyName) {
                print(fontName)
            }
        }
    }
}

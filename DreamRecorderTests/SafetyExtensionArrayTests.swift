//
//  SafetyExtensionArrayTests.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 24..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import XCTest
@testable import DreamRecorder

class SafetyExtensionArrayTest : XCTestCase {
    
    func testSafeArray() {
        
        let integerArray = [1,2,3,4,5]
        
        XCTAssertNil(integerArray[safe: 5])
        
        XCTAssertNil(integerArray[safe: -1])
        
        XCTAssertNotNil(integerArray[safe: 0])
        
        XCTAssertNil(integerArray[safe: 9999])
        
        let stringArray = Array<String>(repeating: "12", count: 1000)
        
        XCTAssertNotNil(stringArray[safe: 5])
        
        XCTAssertNil(stringArray[safe: -1])
        
        XCTAssertNotNil(stringArray[safe: 0])
        
        XCTAssertNil(stringArray[safe: -9999])
    }
    
}

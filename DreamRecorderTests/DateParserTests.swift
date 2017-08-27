//
//  DateParserTests.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 16..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import XCTest
@testable import DreamRecorder

class DateParserTests : XCTestCase {
    
    func testDateParser() {
        let dateParser = DateParser()
        
        var components : DateComponents = {
            var components = DateComponents()
            (components.year, components.month, components.day,components.weekday, components.hour, components.minute) =
                (2016, 8 , 19, 3, 12, 58)
            return components
        }()
        
        let date = Calendar(identifier: .gregorian).date(from: components)

        XCTAssert("12:58 PM" == dateParser.time(from: Calendar(identifier: .gregorian).date(from: components)!))
        
        (components.hour, components.minute) = (11, 0)
        XCTAssert("11:00 AM" == dateParser.time(from: Calendar(identifier: .gregorian).date(from: components)!))
        
        (components.hour, components.minute) = (12, 0)
        XCTAssert("12:00 PM" == dateParser.time(from: Calendar(identifier: .gregorian).date(from: components)!))
        
        (components.hour, components.minute) = (0, 0)
        XCTAssert("00:00 AM" == dateParser.time(from: Calendar(identifier: .gregorian).date(from: components)!))
        
        (components.hour, components.minute) = (11, 59)
        XCTAssert("11:59 AM" == dateParser.time(from: Calendar(identifier: .gregorian).date(from: components)!))
        
        (components.hour, components.minute) = (23, 59)
        XCTAssert("11:59 PM" == dateParser.time(from: Calendar(identifier: .gregorian).date(from: components)!))
        
        (components.hour, components.minute) = (2, 4)
        XCTAssert("02:04 AM" == dateParser.time(from: Calendar(identifier: .gregorian).date(from: components)!))
        
        XCTAssert(2017 == dateParser.year(from: Date()))
        XCTAssert(2016 == dateParser.year(from: date!))
        
        XCTAssert(dateParser.month(from: date!) == 8)
        
        XCTAssert(dateParser.day(from: date!) == "28")
        
    }
    
}

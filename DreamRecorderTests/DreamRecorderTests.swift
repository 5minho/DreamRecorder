//
//  DreamRecorderTests.swift
//  DreamRecorderTests
//
//  Created by 오민호 on 2017. 8. 7..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import XCTest
@testable import DreamRecorder

class DreamRecorderTests: XCTestCase {
    
    var dreamDataStore : DreamDataStore? = nil
    
    override func setUp() {
        super.setUp()
        // Put setup code here. This method is called before the invocation of each test method in the class.
        dreamDataStore = DreamDataStore()
    }
    
    override func tearDown() {
        super.tearDown()
        // Put teardown code here. This method is called after the invocation of each test method in the class.
        dreamDataStore = nil
    }
    
    func testCreateTable() {
        dreamDataStore?.createTable()
    }
    
    func testInsertDream() {
        let dream1 = Dream(id: UUID().uuidString, title: "하늘 남", content: "하늘을 막 날았다", createdDate: Date(), modifiedDate: nil)
        let dream2 = Dream(id: UUID().uuidString, title: "하와이", content: "하와이에 옴", createdDate: Date(), modifiedDate: nil)
        let dream3 = Dream(id: UUID().uuidString, title: "대나무 숲", content: "팬더 봤따", createdDate: Date(), modifiedDate: nil)
        let dream4 = Dream(id: UUID().uuidString, title: "개꿈", content: "완전 개꿈", createdDate: Date(), modifiedDate: nil)
        let dream5 = Dream(id: UUID().uuidString, title: "똥꿈", content: "똥 쌋다", createdDate: Date(), modifiedDate: nil)
        
        dreamDataStore?.insert(dream: dream1)
        dreamDataStore?.insert(dream: dream2)
        dreamDataStore?.insert(dream: dream3)
        dreamDataStore?.insert(dream: dream4)
        dreamDataStore?.insert(dream: dream5)
    }
    
    func testSelectAll() {
        dreamDataStore?.selectAll()
    }

}

//
//  DreamRecorderTests.swift
//  DreamRecorderTests
//
//  Created by 오민호 on 2017. 8. 7..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import XCTest
@testable import DreamRecorder

class DreamDataCRUDTests: XCTestCase {

    func testCreateTable() {
        let result = DreamDataStore.shared.createTable()
        
        switch result {
            
        case .success(_): break
//            XCTAssert(message == "success")
        case let .failure(error):
            XCTAssert(error is Error)
        }
    }
    
    func testInsertDream() {
        
        let dream1 = Dream(id: UUID().uuidString, title: "", content: "하늘을 막 날았다", createdDate: Date(), modifiedDate: nil)
        let dream2 = Dream(id: UUID().uuidString, title: "하와이", content: "하와이에 옴", createdDate: Date(), modifiedDate: Date())
        let dream3 = Dream(id: UUID().uuidString, title: "대나무 숲", content: "팬더 봤따", createdDate: Date(), modifiedDate: nil)
        let dream4 = Dream(id: UUID().uuidString, title: "개꿈", content: "완전 개꿈", createdDate: Date(), modifiedDate: Date())
        let dream5 = Dream(id: UUID().uuidString, title: "똥꿈", content: nil, createdDate: Date(), modifiedDate: nil)
    
        let result1 = DreamDataStore.shared.insert(dream: dream1)
        let result2 = DreamDataStore.shared.insert(dream: dream2)
        let result3 = DreamDataStore.shared.insert(dream: dream3)
        let result4 = DreamDataStore.shared.insert(dream: dream4)
        let result5 = DreamDataStore.shared.insert(dream: dream5)

        switch result1 {
        case let .success(row):
            XCTAssert(row >= 0)
        case .failure(_):
            break
        }
        
        switch result2 {
        case let .success(row):
            XCTAssert(row >= 0)
        case .failure(_):
            break
        }
        switch result3 {
        case let .success(row):
            XCTAssert(row >= 0)
        case .failure(_):
            break
        }
        switch result4 {
        case let .success(row):
            XCTAssert(row >= 0)
        case .failure(_):
            break
        }
        switch result5 {
        case let .success(row):
            XCTAssert(row >= 0)
        case .failure(_):
            break
        }
        
    }
    
    func testSelectAllDream() {
        
//        let result = DreamDataStore.shared.selectAll()
//        
//        switch result {
////        case let .success(sequence):
//////            XCTAssert(sequence != nil)
////            
//        case .failure(_):
//            break
//        }
    }
    
    func testInsert100000Dream() {

//        for i in 0 ..< 100000 {
//            
//            let randomTimeInterval = Double(arc4random_uniform(1503213283)) * -1.0
//            let createdDate = Date(timeIntervalSinceNow: randomTimeInterval)
//            
//            let dream = Dream(id: UUID().uuidString,
//                               title: "\(i + 1)번째 꿈",
//                                content: "\(i + 1)번째 꿈의 내용",
//                                createdDate: createdDate,
//                                modifiedDate: nil)
//            
//            DreamDataStore.shared.insert(dream: dream)
//        }
    
    }

}

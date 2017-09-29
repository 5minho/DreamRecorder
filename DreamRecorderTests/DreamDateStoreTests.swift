//
//  DreamDateStoreTest.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 26..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import XCTest
@testable import DreamRecorder

class DreamDataStoreTests : XCTestCase {
    
    var dreams : [Dream] = []
    var dates : [Date] = []
    var minimumDate : Date?
    var maximumDate : Date?
    

    func testInsertDream() {
        
        let newDream = Dream(title: "newDream", content: "", createdDate: Date(), modifiedDate: nil)
        let result = DreamDataStore.shared.insert(dream: newDream)
        
        switch result {
            
        case let .success(row):
            XCTAssert(row == Int(newDream.id))
            
        case .failure(_):
            break
        }
        
    }
    
    
    func testSelectAllDream() {
        
        let periods : [(Date, Date)] = [(Date(timeIntervalSince1970: 0), Date()),
                                        (Date(timeIntervalSince1970: 86400 * 2), Date()),
                                        (Date(timeIntervalSince1970: 86400 * 5), Date(timeIntervalSince1970: 86400 * 30))]
        
        periods.forEach {
            
            let _ = DreamDataStore.shared.select(period: (from: $0, to: $1))
            
            XCTAssert((DreamDataStore.shared.dreams.last?.createdDate)! <= $1)
            XCTAssert((DreamDataStore.shared.dreams.first?.createdDate)! >= $0)
            
        }
        
    }

    
    func testFilterText() {
        

        let searchTexts = ["내용", "423", "꿈", "42", "번", "번째", "13", "31"]
        
        for searchText in searchTexts {
            
            DreamDataStore.shared.filter(searchText)
            DreamDataStore.shared.filteredDreams.forEach { dream in
                
                if let content = dream.content?.lowercased(),
                    let title = dream.title?.lowercased() {
                    let lowerSearchText = searchText.lowercased()
                    if content.contains(lowerSearchText) == false  && title.contains(lowerSearchText) == false {
                        XCTFail()
                    }
                }
            }
        }
        
        XCTAssert(true)
        
    }
    
    func testDeleteDream() {
        
        DreamDataStore.shared.selectAll()
        
        let rowResult = DreamDataStore.shared.delete(dream: dreams[4])
        
        switch rowResult {
        case let .success(rowId):
            XCTAssertEqual(rowId , 1)
        case .failure(_):
            XCTFail()
        }
        
        
    }
    
    func testUpdateDream() {
        
        let updatingDream = Dream(id: 3, title: "꼬꼬", content: "끽끽끽", createdDate: Date(), modifiedDate: nil)
        var rowResult = DreamDataStore.shared.update(dream: updatingDream)
        
        switch rowResult {
            
        case let .success(row):
            XCTAssert(row == 1)
            
        case .failure:
            XCTFail()
        }
        
        let updatingFailDream = Dream(id: 55, title: "꼬꼬", content: "끽끽끽", createdDate: Date(), modifiedDate: nil)
        rowResult = DreamDataStore.shared.update(dream: updatingFailDream)
        
        switch rowResult {
            
        case let .success(rowResult):
            XCTAssert(rowResult == 0)
            
        case .failure:
            XCTFail()
        }

    }

    func testMinimumDate() {
        
        DreamDataStore.shared.dropTable()
        guard let _ = DreamDataStore.shared.minimumDate() else {
            XCTAssert(true)
            return
        }
        
        readyTest()
        guard let minimumDate = DreamDataStore.shared.minimumDate() else {
            XCTAssert(true)
            return
        }
        
        XCTAssertEqual(minimumDate, self.minimumDate)

    }
    
    func testMaximumDate() {
        
        DreamDataStore.shared.dropTable()
        guard let _ = DreamDataStore.shared.maximumDate() else {
            XCTAssert(true)
            return
        }
        
        readyTest()
        guard let maximumDate = DreamDataStore.shared.maximumDate() else {
            XCTAssert(true)
            return
        }
        
        XCTAssertEqual(maximumDate, self.maximumDate)
        
    }
    
    func testSelectPeriod() {
        
        DreamDataStore.shared.select(period: (dates[2], dates[4]))
        let dreams = DreamDataStore.shared.dreams
        
        XCTAssert(dreams[0].createdDate >= dreams[1].createdDate)
        
        DreamDataStore.shared.select(period: (dates[4], to: dates[2]))
        XCTAssertEqual(dreams[0], DreamDataStore.shared.dreams[0])
        XCTAssertEqual(dreams[1], DreamDataStore.shared.dreams[1])
        
    }

    
    func readyTest() {
        
        DreamDataStore.shared.dropTable()
        DreamDataStore.shared.createTable()
        
        DreamDataStore.shared.insert(dream: dreams[0])
        DreamDataStore.shared.insert(dream: dreams[1])
        DreamDataStore.shared.insert(dream: dreams[2])
        DreamDataStore.shared.insert(dream: dreams[3])
        DreamDataStore.shared.insert(dream: dreams[4])
        
    }
    
}

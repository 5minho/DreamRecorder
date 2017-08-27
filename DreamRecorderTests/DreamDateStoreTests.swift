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
    
    override func setUp() {
        
        DreamDataStore.shared.dropTable()
        DreamDataStore.shared.createTable()
        
        let calander = Calendar(identifier: .gregorian)
        for month in 1...5 {
            
            let dateComponent : DateComponents = {
                var dateComponent = DateComponents()
                (dateComponent.year, dateComponent.month, dateComponent.day) = (2017, month, 1)
                return dateComponent
            }()
            
            if let date = calander.date(from: dateComponent) {
                dates.append(date)
            }
        
        }
        
        minimumDate = dates.first
        maximumDate = dates.last
        
        let dream1 = Dream(title: nil, content: "하늘을 막 날았다", createdDate: dates[0], modifiedDate: nil)
        let dream2 = Dream(title: "하와이", content: "하와이에 옴", createdDate: dates[1], modifiedDate: Date())
        let dream3 = Dream(title: "대나무 숲", content: "팬더 봤따", createdDate: dates[2], modifiedDate: nil)
        let dream4 = Dream(title: "개꿈", content: "완전 개꿈", createdDate: dates[3], modifiedDate: Date())
        let dream5 = Dream(title: "똥꿈", content: nil, createdDate: dates[4], modifiedDate: nil)
        
        dreams = [dream1, dream2, dream3, dream4, dream5]
        
        DreamDataStore.shared.insert(dream: dreams[0])
        DreamDataStore.shared.insert(dream: dreams[1])
        DreamDataStore.shared.insert(dream: dreams[2])
        DreamDataStore.shared.insert(dream: dreams[3])
        DreamDataStore.shared.insert(dream: dreams[4])
        
    }
    
    override func tearDown() {
        DreamDataStore.shared.dropTable()
    }
    
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
        
        let rowResult = DreamDataStore.shared.selectAll()
        
        switch rowResult {
        case .success(_):
            XCTAssertTrue(DreamDataStore.shared.dreams[0] == self.dreams[4] &&
                          DreamDataStore.shared.dreams[1] == self.dreams[3] &&
                          DreamDataStore.shared.dreams[2] == self.dreams[2] &&
                          DreamDataStore.shared.dreams[3] == self.dreams[1] &&
                          DreamDataStore.shared.dreams[4] == self.dreams[0])
            
        case .failure(_):
            XCTFail()
        }
        
        
    }

    
    func testFilterText() {

        var searchText = "1"
        
        DreamDataStore.shared.filter(searchText)
        
        DreamDataStore.shared.filteredDreams.forEach { dream in
            
            if let content = dream.content?.lowercased(),
                let title = dream.title?.lowercased() {
                let lowerSearchText = searchText.lowercased()
                
                XCTAssertTrue(content.contains(lowerSearchText) || title.contains(lowerSearchText))
    
            }
        }
        
        searchText = "개"
        
        DreamDataStore.shared.filter(searchText)
        
        DreamDataStore.shared.filteredDreams.forEach { dream in
            
            if let content = dream.content?.lowercased(),
                let title = dream.title?.lowercased() {
                let lowerSearchText = searchText.lowercased()
                
                XCTAssertTrue(content.contains(lowerSearchText) || title.contains(lowerSearchText))
                
            }
        }
        
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
        XCTAssert(dreams[1].createdDate >= dreams[2].createdDate)
        
        DreamDataStore.shared.select(period: (dates[4], to: dates[2]))
        XCTAssertEqual(dreams[0], DreamDataStore.shared.dreams[0])
        XCTAssertEqual(dreams[1], DreamDataStore.shared.dreams[1])
        XCTAssertEqual(dreams[2], DreamDataStore.shared.dreams[2])
        
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

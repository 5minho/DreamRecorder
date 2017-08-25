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
    
    override func setUp() {
        DreamDataStore.shared.selectAll()
    }
    
    func testFilterTextTest() {
        
        let searchText = "Abc"
        
        DreamDataStore.shared.filter(searchText)
        
        DreamDataStore.shared.filteredDreams.forEach { dream in
            
            if let content = dream.content?.lowercased(),
                let title = dream.title?.lowercased() {
                let lowerSearchText = searchText.lowercased()
                
                XCTAssertTrue(content.contains(lowerSearchText) || title.contains(lowerSearchText))
                
            }
        }
    }

    func testLatestDateTest() {
        
        guard let latestDate = DreamDataStore.shared.latest() else {
            XCTFail()
            return
        }
            
        DreamDataStore.shared.dreams.forEach({ dream in
            
            XCTAssertTrue(latestDate <= dream.createdDate)
            
        })
        
    }
    
}

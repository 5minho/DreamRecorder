//
//  DreamCacheManager.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 20..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import Foundation

class DreamCacheManager {
    
    private let yearsToSaveCount = 130 // (1970 ~ 2100) -> (0 ~ 130)
    private let monthToSaveCount = 13  // 1 ~ 12
    
    private var year = 0
    private var month = 0
    
    private var yearIndex : Int {
        get {
            return year - DreamDataStore.startYearToSave
        }
    }
    
    let dateParser : DateParser
    var cachedDreams : [[[Dream]]]
    
    init() {
        
        self.cachedDreams = [[[Dream]]]()
        self.dateParser = DateParser()
        
        for year in 0 ..< yearsToSaveCount {
            cachedDreams.append([[Dream]]())
            
            for _ in 0 ..< monthToSaveCount {
                cachedDreams[year].append([Dream]())
            }
        }

    }
    
    func insertCache(dream : Dream) {
        
        if let year = dateParser.year(from: dream.createdDate) {
            
            self.year = year
            self.month = dateParser.month(from: dream.createdDate)

            guard var dreams = self.cachedDreams[safe: yearIndex]?[safe: month] else {
                return
            }
        
            for idx in 0 ..< dreams.count {
                
                if dream > dreams[idx] {
                    dreams.insert(dream, at: idx)
                    return
                }
                
            }
            
            dreams.append(dream)
            
        }
        
    }
    
    func deleteCached(dream : Dream) {
        
        if let year = dateParser.year(from: dream.createdDate) {
            
            self.year = year
            self.month = dateParser.month(from: dream.createdDate)
            
            if var dreams = self.cachedDreams[safe: yearIndex]?[safe: month] {
            
                if let idx = dreams.index(of: dream) {
                    dreams.remove(at: idx)
                }
                
            }
            
        }
        
    }
    
}

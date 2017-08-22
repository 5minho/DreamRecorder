//
//  DreamCacheManager.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 20..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import Foundation

class DreamCacheManager {
    
    let yearsCount = 130 // (1970 ~ 2100) -> (0 ~ 130)
    let monthCount = 13  // 1 ~ 12
    
    var cachedDreams : [[[Dream]]]
    
    init() {
        
        cachedDreams = [[[Dream]]]()
        
        for year in 0 ..< yearsCount {
            cachedDreams.append([[Dream]]())
            
            for _ in 0 ..< monthCount {
                cachedDreams[year].append([Dream]())
            }
        }

    }
    
    func insertCache(dream : Dream) {
        
        let dateParser = DateParser()
        
        
        if let year = dateParser.year(from: dream.createdDate) {
            
            let yearIndex = year - 1970
            let month : Int = dateParser.month(from: dream.createdDate)
        
            for idx in 0 ..< self.cachedDreams[yearIndex][month].count {
                
                if dream > self.cachedDreams[yearIndex][month][idx] {
                    self.cachedDreams[yearIndex][month].insert(dream, at: idx)
                    return
                }
                
            }
            self.cachedDreams[yearIndex][month].append(dream)
            
        }
        
    }
    
    func deleteCached(dream : Dream) {
        
        let dateParser = DateParser()
        
        if let year = dateParser.year(from: dream.createdDate) {
            
            let yearIndex = year - 1970
            let month : Int = dateParser.month(from: dream.createdDate)
            
            if let idx = self.cachedDreams[yearIndex][month].index(of: dream) {
                self.cachedDreams[yearIndex][month].remove(at: idx)
            }
        }
    }
    
}

//
//  DreamInfo.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 6..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import Foundation
import SQLite

class Dream {
    
    var id : Int64
    var title : String?
    var content : String?
    var createdDate : Date
    var modifiedDate : Date?
    
    init(id: Int64 = 0, title : String? = nil, content : String? = nil, createdDate : Date, modifiedDate : Date? = nil) {
        self.id = id
        self.title = title
        self.content = content
        self.createdDate = createdDate
    }
    
}

extension Dream : Equatable {
    static func ==(lhs : Dream, rhs : Dream) -> Bool {
        return lhs.id == rhs.id
    }
    
    static func > (lhs : Dream, rhs : Dream) -> Bool {
        return lhs.createdDate > rhs.createdDate
    }
}

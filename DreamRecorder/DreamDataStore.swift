//
//  DreamDataStore.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 7..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import Foundation
import SQLite

extension Date {
    
    static var declaredDatatype: String {
        return String.declaredDatatype
    }
    static func fromDatatypeValue(stringValue: String) -> Date {
        return SQLDateFormatter.date(from: stringValue)!
    }
    var datatypeValue: String {
        return SQLDateFormatter.string(from: self)
    }
    
}

let SQLDateFormatter: DateFormatter = {
    let formatter = DateFormatter()
    formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS"
    formatter.locale = Locale(identifier: "en_US_POSIX")
    formatter.timeZone = TimeZone(secondsFromGMT: 0)
    return formatter
    
}()

class DreamDataStore {
    var dreams : [Dream] = []
    var dbManager = DBManager.shared
    
    private struct DreamTable {
        static let table = Table("Dreams")
        
        struct Column {
            static let id = Expression<String>("id")
            static let title = Expression<String?>("title")
            static let content = Expression<String?>("content")
            static let createdDate = Expression<Date>("createdDate")
            static let modifiedDate = Expression<Date?>("modifiedDate")
        }
        
    }
    
    func createTable() {
        let createTableResult = self.dbManager.createTable(statement: DreamTable.table.create { table in
            table.column(DreamTable.Column.id, primaryKey: true)
            table.column(DreamTable.Column.title)
            table.column(DreamTable.Column.content)
            table.column(DreamTable.Column.createdDate)
            table.column(DreamTable.Column.modifiedDate)
        })
        
        switch createTableResult {
        case .success:
            print("Table Created")
        case let .failure(_):
            print("error")
        }
    }
    
    func selectAll() {
        let rowsResult = dbManager.selectAll(query: DreamTable.table)
        switch rowsResult {
        case let .success(rows):
            rows.forEach({
                let id = $0.get(DreamTable.Column.id)
                let title = $0.get(DreamTable.Column.title)
                let content = $0.get(DreamTable.Column.content)
                let createdDate = $0.get(DreamTable.Column.createdDate)
                let modifiedDate = $0.get(DreamTable.Column.modifiedDate)
                let dream = Dream(id: id, title: title, content: content, createdDate: createdDate, modifiedDate: modifiedDate)
                if self.dreams.index(of: dream) == nil {
                    dreams.append(dream)
                }
            })
        case let .failure(error):
            print(error)
        }
    }
    
    func insert(dream: Dream) {
        let insert = DreamTable.table.insert (
            DreamTable.Column.id <- dream.id,
            DreamTable.Column.title <- dream.title,
            DreamTable.Column.content <- dream.content,
            DreamTable.Column.createdDate <- dream.createdDate,
            DreamTable.Column.modifiedDate <- dream.modifiedDate
        )
        
        let result = dbManager.insertRow(insert: insert)
        
        switch result {
        case let .success(rowID):
            print(rowID)
        default:
            print("default")
        }
    }
    
}

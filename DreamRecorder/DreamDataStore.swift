//
//  DreamDataStore.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 7..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import Foundation
import SQLite

class DreamDataStore {
    
    static let shared : DreamDataStore = DreamDataStore()
    
    private init() {}
    
    struct NotificationName {
        
        static let didDeleteDream = Notification.Name("didDeleteDream")
        static let didAddDream = Notification.Name("didAddDream")
        
    }
    
    private var dreams : [Dream] = []
    
    var count : Int {
        return dreams.count
    }
    
    let dbManager = DBManager.shared
    
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
    
    func dream(at index : Int) -> Dream? {
        guard index < self.count else {
            return nil
        }
        return dreams[index]
    }
    
    
    @discardableResult func createTable() -> TableResult {
        
        let createTableResult = self.dbManager.createTable(statement: DreamTable.table.create(ifNotExists: true) { table in
            table.column(DreamTable.Column.id, primaryKey: true)
            table.column(DreamTable.Column.title)
            table.column(DreamTable.Column.content)
            table.column(DreamTable.Column.createdDate)
            table.column(DreamTable.Column.modifiedDate)
        })
        
        switch createTableResult {
        case .success:
            print("Table Created")
        case .failure(_):
            print("error")
        }
        
        return createTableResult
        
    }
    
    @discardableResult func selectAll() -> RowsResult {
        
        let rowsResult = dbManager.selectAll(query: DreamTable.table.order(DreamTable.Column.createdDate.desc))
        switch rowsResult {
            
        case let .success(rows):
            rows.forEach({
                let id = $0.get(DreamTable.Column.id)
                let title = $0.get(DreamTable.Column.title)
                let content = $0.get(DreamTable.Column.content)
                let createdDate = $0.get(DreamTable.Column.createdDate)
                let modifiedDate = $0.get(DreamTable.Column.modifiedDate)
                print(title! + " " + content!)
                let dream = Dream(id: id, title: title, content: content, createdDate: createdDate, modifiedDate: modifiedDate)
                if self.dreams.index(of: dream) == nil {
                    dreams.append(dream)
                }
            })
            
        case let .failure(error):
            print(error)
        }
        
        return rowsResult
    }

    
    @discardableResult func insert(dream: Dream) -> RowResult {
        
        let insert = DreamTable.table.insert (
            DreamTable.Column.id <- dream.id,
            DreamTable.Column.title <- dream.title,
            DreamTable.Column.content <- dream.content,
            DreamTable.Column.createdDate <- dream.createdDate,
            DreamTable.Column.modifiedDate <- dream.modifiedDate
        )
        
        let result = dbManager.insertRow(insert: insert)
        
        switch result {
        case .success(_):
//            self.dreams.append(dream)
            self.dreams.insert(dream, at: 0)
//            self.dreams.sort(by: >)
            NotificationCenter.default.post(name: NotificationName.didAddDream, object: nil)
            
        case .failure(_):
            print("default")
        }
        
        return result
    }
    
    @discardableResult func update(dream: Dream) -> RowResult {
        
        let updateRow = DreamTable.table.filter(DreamTable.Column.id == dream.id)
        
        let result = self.dbManager.updateRow(update: updateRow.update(
            DreamTable.Column.id <- dream.id,
            DreamTable.Column.title <- dream.title,
            DreamTable.Column.content <- dream.content,
            DreamTable.Column.createdDate <- dream.createdDate,
            DreamTable.Column.modifiedDate <- dream.modifiedDate
            )
        )
        
        switch result {
        case .success:
            print("Success: update row \(dream.id)")
        case let .failure(error):
            print("error: \(error)")
        }
        
        return result
    }

    
    @discardableResult func delete(dream: Dream, at index : Int? = nil) -> RowResult {
        
        let deletingRow = DreamTable.table.filter(DreamTable.Column.id == dream.id)
        let result = self.dbManager.deleteRow(delete: deletingRow.delete())
        
        
        switch result {
            
        case .success:
            print("Success: delete row \(dream.id)")
            guard let idx : Int = index ?? dreams.index(of: dream) else {
                return result
            }
            self.dreams.remove(at: idx)
            NotificationCenter.default.post(name: NotificationName.didDeleteDream, object: nil, userInfo : ["index" : idx])
            
        case let .failure(error):
            print("error: \(error)")
        }
        
        return result
    }
    
    func filter(_ searchText : String) -> [Dream] {
        return self.dreams.filter ({
            let title = $0.title?.lowercased() ?? ""
            let content = $0.content?.lowercased() ?? ""
            return title.contains(searchText.lowercased()) || content.contains(searchText.lowercased())
        })
    }
}

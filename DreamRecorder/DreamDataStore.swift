
//  DreamDataStore.swift
//  DreamRecorder
//
//  Created by 오민호 on 2017. 8. 7..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import Foundation
import SQLite

extension Notification.Name {

    /// DraemDataStore -> DreamListViewController(UI).
    static let DreamDataStoreDidAddDream = Notification.Name("DreamDataStoreDidAddDream")
    static let DreamDataStoreDidDeleteDream = Notification.Name("DreamDataStoreDidDeleteDream")
    static let DreamDataStoreDidUpdateDream = Notification.Name("DreamDataStoreDidUpdateDream")
}

class DreamDataStore {
    
    static let shared : DreamDataStore = DreamDataStore()
    
    private init() {}
    
//    private var cacheManager = DreamCacheManager()
    
    var dreams : [Dream] = []
    var filteredDreams : [Dream] = []
    
    var count : Int {
        return dreams.count
    }
    
    let dbManager = DBManager.shared
    
    struct DreamTable {
        
        static let table = Table("Dreams")
        
        struct Column {
            
            static let id = Expression<Int64>("id")
            static let title = Expression<String?>("title")
            static let content = Expression<String?>("content")
            static let createdDate = Expression<Date>("createdDate")
            static let modifiedDate = Expression<Date?>("modifiedDate")
            
        }
        
    }
    
    struct Virtual {
        
        static let table = VirtualTable("VDreams")
        
        struct Column {
            
            static let id = Expression<Int64>("id")
            static let title = Expression<String?>("title")
            static let content = Expression<String?>("content")
            static let createdDate = Expression<Date>("createdDate")
            static let modifiedDate = Expression<Date?>("modifiedDate")
            
        }
        
    }

    @discardableResult func createTable() -> TableResult {
        
        let createTableResult = self.dbManager.createTable(statement: DreamTable.table.create(ifNotExists: true) { table in
            table.column(DreamTable.Column.id, primaryKey: .autoincrement)
            table.column(DreamTable.Column.title)
            table.column(DreamTable.Column.content)
            table.column(DreamTable.Column.createdDate)
            table.column(DreamTable.Column.modifiedDate)
        })
        
        let config = FTS4Config()
            .column(Virtual.Column.id, [.unindexed])
            .column(Virtual.Column.title)
            .column(Virtual.Column.content)
            .column(Virtual.Column.createdDate, [.unindexed])
            .column(Virtual.Column.modifiedDate, [.unindexed])
        
        let _ = self.dbManager.createTable(statement: Virtual.table.create(.FTS4(config)))
        
        switch createTableResult {
            
        case .success:
            print("Table Created")
        case .failure(_):
            print("error")
            
        }
        
        return createTableResult
        
    }
    
    func select(period : (from: Date, to: Date)) {

        var tmpPeriod : (from: Date, to: Date) = period
        
        if period.from > period.to {
            tmpPeriod = (period.to, period.from)
        }
        
        let nextDate = period.to.addingTimeInterval(86400)
        
        let fromDate = Expression<Date>(value: tmpPeriod.from)
        let toDate = Expression<Date>(value: nextDate)
        
        let rowsResult = dbManager.selectAll(query: DreamTable.table.filter(DreamTable.Column.createdDate >= fromDate
            && DreamTable.Column.createdDate <= toDate)
            .order(DreamTable.Column.createdDate.desc))
        
        dreams = []
        
        switch rowsResult {
            
        case let .success(rows) :
            
            rows.forEach({
                
                let id = $0.get(DreamTable.Column.id)
                let title = $0.get(DreamTable.Column.title)
                let content = $0.get(DreamTable.Column.content)
                let createdDate = $0.get(DreamTable.Column.createdDate)
                let modifiedDate = $0.get(DreamTable.Column.modifiedDate)
                
                let dream = Dream(id: id,title: title, content: content, createdDate: createdDate, modifiedDate: modifiedDate)
                dreams.append(dream)
            })
            
        case let .failure(error) :
            print(error)
        }
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

            DreamTable.Column.title <- dream.title,
            DreamTable.Column.content <- dream.content,
            DreamTable.Column.createdDate <- dream.createdDate,
            DreamTable.Column.modifiedDate <- dream.modifiedDate
            
        )
        
        let insertAtVitualTable = Virtual.table.insert (
            
            Virtual.Column.id <- dream.id,
            Virtual.Column.title <- dream.title,
            Virtual.Column.content <- dream.content,
            Virtual.Column.createdDate <- dream.createdDate,
            Virtual.Column.modifiedDate <- dream.modifiedDate
            
        )
        
        let result = dbManager.insertRow(insert: insert)
        let _ = dbManager.insertRow(insert: insertAtVitualTable)
        
        switch result {
            
        case let .success(row):
            dream.id = Int64(row)
            self.dreams.insert(dream, at: 0)
            NotificationCenter.default.post(name: .DreamDataStoreDidAddDream, object: nil)
            
        case .failure(_):
            print("default")
            
        }
        
        return result
    }
    
    @discardableResult func update(dream: Dream) -> RowResult {
        
        let updateRow = DreamTable.table.filter(DreamTable.Column.id == dream.id)
        
        let result = self.dbManager.updateRow(update: updateRow.update(
            
            DreamTable.Column.title <- dream.title,
            DreamTable.Column.content <- dream.content,
            DreamTable.Column.modifiedDate <- dream.modifiedDate
            
            )
        )
        
//        dbManager.updateRow(update: updateRow.update(
//            Virtual.Column.id <- dream.id
//            Virtual.Column.title <- dream.title,
//            Virtual.Column.content <- dream.content,
//            Virtual.Column.
//            DreamTable.Column.modifiedDate <- dream.modifiedDate
//        )
//        )
        
        switch result {
            
        case .success:
            if let idx = self.dreams.index(of: dream) {
                dreams[idx] = dream
            }
            
            NotificationCenter.default.post(name: .DreamDataStoreDidUpdateDream, object: nil)
            print("Success: update row \(dream.id)")
            
        case let .failure(error):
            print("error: \(error)")
            
        }
        
        return result
    }

    
    @discardableResult func delete(dream: Dream) -> RowResult {
        
        let deletingRow = DreamTable.table.filter(DreamTable.Column.id == dream.id)
        let result = self.dbManager.deleteRow(delete: deletingRow.delete())
        
        switch result {
            
        case .success :
        
            var userInfo : [String : Int] = [:]
            
            if let idx = dreams.index(of: dream) {
                userInfo["row"] = idx
                self.dreams.remove(at: idx)
            }
            
            if let deletedIdx = filteredDreams.index(of: dream) {
                userInfo["rowInFiltering"] = deletedIdx
                self.filteredDreams.remove(at: deletedIdx)
            }
            
            NotificationCenter.default.post(name: .DreamDataStoreDidDeleteDream, object: nil, userInfo : userInfo)
            
        case let .failure(error) :
            print("error: \(error)")
            
        }
        
        return result
        
    }
    
    func filter(_ searchText : String) {
        
        let filterResult = dbManager.filterRow(query: DreamTable.table.filter(
            DreamTable.Column.title.like("%\(searchText)%") ||
            DreamTable.Column.content.like("%\(searchText)%")
            )
        )

        filteredDreams = []
        
        switch filterResult {
            
        case let .success(rows):
            
            rows.forEach({
                let id = $0.get(DreamTable.Column.id)
                let title = $0.get(DreamTable.Column.title)
                let content = $0.get(DreamTable.Column.content)
                let createdDate = $0.get(DreamTable.Column.createdDate)
                let modifiedDate = $0.get(DreamTable.Column.modifiedDate)
                
                let dream = Dream(id: id, title: title, content: content, createdDate: createdDate, modifiedDate: modifiedDate)
                filteredDreams.append(dream)
            })
            
        case .failure(_):
            print("fail")

        }

    }

    func ftsFilter(_ searchText : String) {
        
            filteredDreams = []
    
            let searchQuery: QueryType = Virtual.table.match(searchText + "*")
    
            let filterResult = dbManager.selectAll(query: searchQuery)
    
            switch filterResult {
    
            case let .success(rows):
    
                rows.forEach({
    
                    let id = $0.get(Virtual.Column.id)
                    let title = $0.get(Virtual.Column.title)
                    let content = $0.get(Virtual.Column.content)
                    let createdDate = $0.get(DreamTable.Column.createdDate)
                    let modifiedDate = $0.get(DreamTable.Column.modifiedDate)
    
                    let dream = Dream(id: id, title: title, content: content, createdDate: createdDate, modifiedDate: modifiedDate)
                    filteredDreams.append(dream)
                    
                })
                
            case .failure(_):
                print("fail")
                
            }
    }
    func minimumDate() -> Date? {
        
        do {
            
            let minDate = try dbManager.db.scalar(DreamTable.table.select(DreamTable.Column.createdDate.min))
            return minDate
            
        } catch {
            
            print(error)
            return nil
            
        }
        
    }
    
    func maximumDate() -> Date? {
        
        do {
            
            let maxDate = try dbManager.db.scalar(DreamTable.table.select(DreamTable.Column.createdDate.max))
            return maxDate
            
        } catch {
            
            print(error)
            return nil
            
        }
        
    }
    
    func dropTable() {
        try? dbManager.db.run(DreamTable.table.drop())
    }
    
    func dropVitualTable() {
        try? dbManager.db.run(Virtual.table.drop())
    }
    
}

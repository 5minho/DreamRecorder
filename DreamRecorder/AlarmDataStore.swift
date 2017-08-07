//
//  AlarmDataStore.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 7..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import Foundation
import SQLite

class AlarmDataStore: NSObject {

    let manager: DBManagerable = DBManager.shared
    
    private struct AlarmTable {
        static let table = Table("alarms")
        
        struct Column {
            static let id = Expression<Int64>("id")
            static let name = Expression<String?>("name")
        }
    }
    
    func createTable(){
        
        let tableResult = self.manager.createTable(statement: AlarmTable.table.create { (t) in
            t.column(AlarmTable.Column.id, primaryKey: true)
            t.column(AlarmTable.Column.name)
        })
        switch tableResult {
        case .success:
            print("Table Created")
        case let .failure(error):
            print("error")
        }
    }
    
    func selectAll(){
        let rowsResult = manager.selectAll(query: AlarmTable.table)
        switch rowsResult {
        case let .success(rows):
            for alarm in rows {
                print("id : \(alarm[AlarmTable.Column.id]), name: \(alarm[AlarmTable.Column.name])")
            }
        case let .failure(error):
            print(error)
        }
        
    }
    
    func insertAlarm(alarm: Alarm){
        let insert = AlarmTable.table.insert(AlarmTable.Column.name <- alarm.id, AlarmTable.Column.name <- AlarmTable.Column.name)
        
        let result = manager.insertRow(insert: insert)
        
        switch result {
        case let .success(rowID):
            print(rowID)
        default:
            print("default")
        }
    }
}

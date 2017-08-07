//
//  DBManager.swift
//  DreamRecorder
//
//  Created by JU HO YOON on 2017. 8. 7..
//  Copyright © 2017년 BoostCamp. All rights reserved.
//

import SQLite

enum TableResult {
    case success
    case failure(DBError)
}

enum RowsResult {
    case success(AnySequence<Row>)
    case failure(DBError)
}

enum RowResult {
    case success(Int)
    case failure(DBError)
}

enum DBError {
    case transactionError
    case connectionError
}

protocol DBManagerable: NSObjectProtocol {
    func selectAll(query: QueryType) -> RowsResult
    func createTable(statement: String) -> TableResult
    func insertRow(insert: Insert) -> RowResult
    func updateRow(update: Update) -> RowResult
    func deleteRow(delete: Delete) -> RowResult
}

class DBManager: NSObject, DBManagerable {
    
    static var shared: DBManager = DBManager()
    
    let db: Connection = {
        let url = FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).first!
        let db = try! Connection("\(url.path)/db.sqlite3")
        return db
    }()
    
    func clearTable(){
        
        let table = Table("alarms")
        try! db.run(table.drop())
    }
    
    func selectAll(query: QueryType) -> RowsResult {
        do {
            let rows = try db.prepare(query)
            return .success(rows)
        } catch {
            print(error)
            return .failure(.transactionError)
        }
    }
    
    func createTable(statement: String) -> TableResult {
        do {
            try self.db.run(statement)
            return .success
        } catch {
            print(error)
            return .failure(.transactionError)
        }
    }
    
    
    func insertRow(insert: Insert) -> RowResult {
        do {
            let rowID = try self.db.run(insert)
            return .success(Int(rowID))
        } catch {
            print(error)
            return .failure(.transactionError)
        }
    }
    
    func updateRow(update: Update) -> RowResult {
        do {
            let rowID = try self.db.run(update)
            return .success(rowID)
        } catch {
            print(error)
            return .failure(.transactionError)
        }
    }
    
    func deleteRow(delete: Delete) -> RowResult {
        do {
            let rowID = try self.db.run(delete)
            return .success(rowID)
        } catch {
            print(error)
            return .failure(.transactionError)
        }
    }
    
}

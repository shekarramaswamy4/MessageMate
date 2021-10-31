//
//  Data.swift
//  Assistant
//
//  Created by shekar ramaswamy on 10/31/21.
//

import Foundation
import GRDB

class Data {
    
    static func readAndFormatChats() {
        var url = try? FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        url = url!.appendingPathComponent("Messages", isDirectory: true).appendingPathComponent("chat.db", isDirectory: false)
        
        do {
            let dbQueue = try DatabaseQueue(path: url!.absoluteString)
        } catch {
            print(error)
        }
    }
    
    static func readAndFormatContacts() {
        var url = try? FileManager.default.url(for: .libraryDirectory, in: .userDomainMask, appropriateFor: nil, create: false)
        url = url!.appendingPathComponent("Application Support", isDirectory: true)
            .appendingPathComponent("AddressBook", isDirectory: true)
            .appendingPathComponent("Sources", isDirectory: true)
        
        // Remove file:// from beginning of string
        var cleaned = String(url!.absoluteString.dropFirst(7))
        cleaned = cleaned.replacingOccurrences(of: "%20", with: " ")

        let fileList = try! FileManager.default.contentsOfDirectory(atPath: cleaned)
        
        let idToName: [String:String] = [:]
        for f in fileList {
            var dbUrl = url
            dbUrl = dbUrl!.appendingPathComponent(f, isDirectory: true)
                .appendingPathComponent("AddressBook-v22.abcddb", isDirectory: false)
            
            do {
                let dbQueue = try DatabaseQueue(path: dbUrl!.absoluteString)
                
                let query = "select ZSORTINGFIRSTNAME as name, Z_PK as id from ZABCDRECORD order by Z_PK asc"
                try dbQueue.read { db in
                    let rows = try Row.fetchCursor(db, sql: query)
                    while let row = try rows.next() {
                        let id = row["id"]
                        let name = row["name"]
                        print(id, name)
                    }
                }
                
                
            } catch {
                print(error)
            }
        }
    }
}
